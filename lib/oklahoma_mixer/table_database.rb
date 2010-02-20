require "oklahoma_mixer/error"
require "oklahoma_mixer/array_list"
require "oklahoma_mixer/hash_map"
require "oklahoma_mixer/query"
require "oklahoma_mixer/hash_database"
require "oklahoma_mixer/table_database/c"

module OklahomaMixer
  class TableDatabase < HashDatabase
    module Paginated
      attr_accessor :current_page, :per_page, :total_entries
      
      def total_pages
        (total_entries / per_page.to_f).ceil
      end
      
      def out_of_bounds?
        current_page > total_pages
      end

      def offset
        (current_page - 1) * per_page
      end

      def previous_page
        current_page > 1 ? (current_page - 1) : nil
      end

      def next_page
        current_page < total_pages ? (current_page + 1) : nil
      end
    end

    ################################
    ### Getting and Setting Keys ###
    ################################
    
    def store(key, value, mode = nil, &dup_handler)
      if mode == :add and dup_handler.nil?
        super
      elsif dup_handler
        warn "block supersedes mode argument" unless mode.nil?
        k        = cast_key_in(key)
        callback = lambda { |old_value_pointer, old_size, returned_size, _|
          old_value         = cast_from_null_terminated_colums(
                                *old_value_pointer.get_bytes(0, old_size)
                              )
          replacement, size = cast_to_null_terminated_colums( yield( key,
                                                                     old_value,
                                                                     value ) )
          returned_size.put_int(0, size)
          pointer = Utilities.malloc(size)
          pointer.put_bytes(0, replacement) unless pointer.address.zero?
          pointer
        }
        try(:putproc, k, cast_to_null_terminated_colums(value), callback, nil)
        value
      else
        Utilities.temp_map do |map|
          map.update(value) { |string|
            cast_to_bytes_and_length(string)
          }
          result = super(key, map, mode, &dup_handler)
          result == map ? value : result
        end
      end
    end
    alias_method :[]=, :store

    def fetch(key, *default)
      if value = try( :get, cast_key_in(key),
                      :failure  => lambda { |value| value.address.zero? },
                      :no_error => {22 => nil} )
        cast_value_out(value)
      else
        if block_given?
          warn "block supersedes default value argument" unless default.empty?
          yield key
        elsif not default.empty?
          default.first
        else
          fail IndexError, "key not found"
        end
      end
    end
    
    def generate_unique_id
      try(:genuid, :failure => -1)
    end
    alias_method :uid, :generate_unique_id
    
    #################
    ### Iteration ###
    #################
    
    def each
      try(:iterinit)
      loop do
        pointer = try( :iternext3,
                       :failure  => lambda { |value| value.address.zero? },
                       :no_error => {22 => nil} )
        return self unless pointer
        value = cast_value_out(pointer)
        key   = value.delete("")
        yield [key, value]
      end
    end
    alias_method :each_pair, :each
    
    ###############
    ### Queries ###
    ###############
    
    def all(options = { }, &iterator)
      query(options) do |q|
        mode = results_mode(options)
        if block_given?
          results  = self
          callback = lambda { |key_pointer, key_size, doc_map, _|
            if mode != :docs
              key = cast_key_out(key_pointer.get_bytes(0, key_size))
            end
            if mode != :keys
              map = HashMap.new(doc_map)
              doc = map.to_hash { |string| cast_to_encoded_string(string) }
            end
            flags = case mode
                    when :keys then yield(key)
                    when :docs then yield(doc)
                    else            yield(key, doc)
                    end
            Array(flags).inject(0) { |returned_flags, flag|
              returned_flags | case flag.to_s
                               when "update"
                                 if mode != :keys
                                   map.replace(doc) { |key_or_value|
                                     cast_to_bytes_and_length(key_or_value)
                                   }
                                 end
                                 lib::FLAGS[:TDBQPPUT]
                               when "delete" then lib::FLAGS[:TDBQPOUT]
                               when "break"  then lib::FLAGS[:TDBQPSTOP]
                               else               0
                               end
            }
          }
        else
          results  = mode != :hoh ? [ ] : { }
          callback = lambda { |key_pointer, key_size, doc_map, _|
            if mode == :docs
              results << cast_value_out(doc_map, :no_free)
            else
              key = cast_key_out(key_pointer.get_bytes(0, key_size))
              case mode
              when :keys
                results << key
              when :hoh
                results[key] = cast_value_out(doc_map, :no_free)
              when :aoh
                results << cast_value_out(doc_map, :no_free).
                           merge(:primary_key => key)
              else
                results << [key, cast_value_out(doc_map, :no_free)]
              end
            end
            0
          }
        end
        unless lib.qryproc(q.pointer, callback, nil)
          error_code    = lib.ecode(@db)
          error_message = lib.errmsg(error_code)
          fail Error::QueryError, "#{error_message} (error code #{error_code})"
        end
        results
      end
    end
    
    def first(options = { })
      all(options.merge(:limit => 1)).first
    end
    
    def count(options = { })
      count = 0
      all(options) { count += 1 }
      count
    end
    
    def paginate(options)
      mode    = results_mode(options)
      results = (mode != :hoh ? [ ] : { }).extend(Paginated)
      fail Error::QueryError, ":page argument required" \
        unless options.include? :page
      results.current_page = (options[:page] || 1).to_i
      fail Error::QueryError, ":page must be >= 1" if results.current_page < 1
      results.per_page = (options[:per_page] || 30).to_i
      fail Error::QueryError, ":per_page must be >= 1" if results.per_page < 1
      results.total_entries = 0
      all( options.merge( :select => :keys_and_docs,
                          :limit  => nil ) ) { |key, value|
        if results.total_entries >= results.offset and
           results.size          <  results.per_page
          case mode
          when :keys
            results << key
          when :docs
            results << value
          when :hoh
            results[key] = value
          when :aoh
            results << value.merge(:primary_key => key)
          else
            results << [key, value]
          end
        end
        results.total_entries += 1
      }
      results
    end
    
    def union(q, *queries)
      search([q] + queries, lib::SEARCHES[:TDBMSUNION])
    end
    
    def intersection(q, *queries)
      search([q] + queries, lib::SEARCHES[:TDBMSISECT])
    end
    alias_method :isect, :intersection
    
    def difference(q, *queries)
      search([q] + queries, lib::SEARCHES[:TDBMSDIFF])
    end
    alias_method :diff, :difference
    
    ###############
    ### Indexes ###
    ###############
    
    def add_index(column, type, keep = false)
      type =  case type.to_s
              when "lexical", "string"  then lib::INDEXES[:TDBITLEXICAL]
              when "decimal", "numeric" then lib::INDEXES[:TDBITDECIMAL]
              when "token"              then lib::INDEXES[:TDBITTOKEN]
              when "qgram"              then lib::INDEXES[:TDBITQGRAM]
              else
                fail Error::IndexError, "unknown index type"
              end
      type |= lib::INDEXES[:TDBITKEEP] if keep
      try( :setindex,
           cast_to_bytes_and_length(column_name(column)).first,
           type,
           :no_error => {21 => false} )
    end
    
    def remove_index(column)
      try( :setindex,
           cast_to_bytes_and_length(column_name(column)).first,
           lib::INDEXES[:TDBITVOID],
           :no_error => {2 => false} )
    end
    
    def optimize_index(column)
      try( :setindex,
           cast_to_bytes_and_length(column_name(column)).first,
           lib::INDEXES[:TDBITOPT],
           :no_error => {2 => false} )
    end
    alias_method :defrag_index, :optimize_index
    
    #######
    private
    #######
    
    def tune(options)
      super
      if options.values_at(:bnum, :apow, :fpow, :opts).any?
        optimize(options.merge(:tune => true))
      end
      if options.values_at(:rcnum, :lcnum, :ncnum).any?
        setcache(options)
      end
    end
    
    def setcache(options)
      try( :setcache,
           options.fetch(:rcnum, 0).to_i,
           options.fetch(:lcnum, 0).to_i,
           options.fetch(:ncnum, 0).to_i )
    end
    
    def cast_value_in(value)
      value.pointer
    end
    
    def cast_value_out(pointer, no_free = false)
      map = HashMap.new(pointer)
      map.to_hash { |string| cast_to_encoded_string(string) }
    ensure
      map.free if map and not no_free
    end
    
    def cast_from_null_terminated_colums(string)
      Hash[*string.split("\0").map { |s| cast_to_encoded_string(s) }]
    end
    
    def cast_to_null_terminated_colums(hash)
      cast_to_bytes_and_length(hash.to_a.flatten.join("\0"))
    end
    
    def column_name(column)
      case column
      when :primary_key, :pk then ""
      else                        column
      end
    end
    
    def query(options = { })
      query      = Query.new(@db)
      conditions = Array(options[:conditions])
      conditions = [conditions] unless conditions.empty? or
                                       conditions.first.is_a? Array
      conditions.each do |condition|
        fail Error::QueryError,
             "condition must be column, operator, and expression" \
          unless condition.size.between? 3, 4
        query.condition( column_name(condition.first),
                         *condition[1..-1] ) { |string|
          cast_to_bytes_and_length(string).first
        }
      end
      unless options[:order].nil?
        order = options[:order] == "" ? [""] : Array(options[:order])
        fail Error::QueryError, "order must have a field and can have a type" \
          unless order.size.between? 1, 2
        order[0] = column_name(order[0])
        query.order(*order) { |string|
          cast_to_bytes_and_length(string).first
        }
      end
      unless options[:limit].nil?
        query.limit(options[:limit], options[:offset])
      end
      if block_given?
        yield query
      else
        query
      end
    ensure
      query.free if query and block_given?
    end
    
    def results_mode(options)
      case options[:select].to_s
      when /\A(?:primary_)?keys?\z/i then :keys
      when /\Adoc(?:ument)?s?\z/i    then :docs
      else
        case options[:return].to_s
        when /\Ah(?:ash_)?o(?:f_)?h(?:ash)?e?s?\z/i  then :hoh
        when /\Aa(?:rray_)?o(?:f_)?a(?:rray)?s?\z/i  then :aoa
        when /\Aa(?:rray_)?o(?:f_)?h(?:ash)?e?s?\z/i then :aoh
        else
          if RUBY_VERSION < "1.9" and not options[:order].nil? then :aoa
          else                                                      :hoh
          end
        end
      end
    end
    
    def search(queries, operation)
      mode = results_mode(queries.first)
      qs   = queries.map { |q| query(q) }
      keys = ArrayList.new( Utilities.temp_pointer(qs.size) do |pointer|
        pointer.write_array_of_pointer(qs.map { |q| q.pointer })
        lib.metasearch(pointer, qs.size, operation)
      end )
      case mode
      when :keys
        keys.map { |key| cast_key_out(key) }
      when :docs
        keys.map { |key| self[cast_key_out(key)] }
      when :hoh
        results = { }
        while key = keys.shift { |k| cast_key_out(k) }
          results[key] = self[key]
        end
        results
      when :aoh
        keys.map { |key|
          key = cast_key_out(key)
          self[key].merge(:primary_key => key)
        }
      else
        keys.map { |key|
          key = cast_key_out(key)
          [key, self[key]]
        }
      end
    ensure
      if qs
        qs.each do |q|
          q.free
        end
      end
      keys.free if keys
    end
  end
end
