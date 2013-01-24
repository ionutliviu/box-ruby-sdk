module Box
  # Represents a folder or file stored on Box. Any attributes or actions
  # typical to a Box item can be accessed through this class. The {Item}
  # class contains only methods shared by {Folder} and {File}, and should
  # not be instanciated directly.

  class Item
    # @return [Api] The {Api} used by this item.
    attr_accessor :api

    # @return [Hash] The hash of info for this item.
    attr_accessor :data

    # Create a new item representing either a file or folder.
    #
    # @param [Api] api The {Api} instance used to generate requests.
    # @param [Folder] parent The {Folder} parent of this item.
    # @param [Hash] info The hash of initial info for this item.
    def initialize(api, info = Hash.new)
      @api = api
      @data = Hash.new

      update_info(info) # merges with the info hash, and renames some fields
    end

    # @return [String] The id of this item.
    def id
      # overloads Object#id
      @data[:id]
    end

    # Get the info for this item. Uses a cached copy if avaliable,
    # or else it is fetched from the api.
    #
    # @param [Boolean] refresh Does not use the cached copy if true.
    # @return [Item] self
    def info(refresh = false)
      return self if @cached_info and not refresh

      @cached_info = true
      update_info(get_info)

      self
    end

    def item_type(refresh = false)
      return @data[:type] if @data.key?(:type)
      self.info(refresh)
      return @data[:type] if @data.key?(:type)
    end

    # Provides an easy way to access this item's info.
    #
    # @example
    #   item.name # returns @data['name'] or fetches it if not cached
    def method_missing(sym, *args, &block)
      # determine whether to refresh the cache
      refresh = args ? args.first : false

      # return the value if it already exists
      return @data[sym] if @data.key?(sym)

      # value didn't exist, so try to update the info
      self.info(refresh)

      # try returning the value again
      return @data[sym] if @data.key?(sym)

      # we didn't find a value, so it must be invalid
      # call the normal method_missing function
      super
    end

    # Handles some cases in method_missing, but won't always be accurate.
    def respond_to?(sym)
      @data.key?(sym) or super
    end

    def ==(other)
      self.class == other.class and self.id == other.id
    end

    protected

    # Fetches this item's info from the api.
    #
    # @return [Hash] The info for the item.
    def get_info; Hash.new; end

    # @param [Hash] info A hash to be merged this item's info
    def update_info(info)
      ninfo = Hash.new

      info.each do |key, value|
        key = key.to_sym

        if key == :item_collection
          key = :items
          value = value['entries']
        elsif key == :parent_folder
          key = :parent
        end

        multi = value.is_a?(Array)
        value = [ value ] unless multi

        value.collect! do |val|
          item_type = case val.delete('type')
            when 'file' then Box::File
            when 'folder' then Box::Folder
            when 'comment' then Box::Comment
            when 'discussion' then Box::Discussion
            when 'version' then Box::Version
          end if val.is_a?(Hash)

          val = item_type.new(@api, val) if item_type
          val
        end

        value = value.first unless multi
        ninfo[key] = value
      end

      @data.merge!(ninfo) # merge in the updated info
    end
  end
end
