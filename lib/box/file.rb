require 'box/item'
require 'box/comment'
require 'box/version'

module Box
  # Represents a file stored on Box. Any attributes or actions typical to
  # a Box file can be accessed through this class.

  class File < Item
    def id
      super || @data[:file_id]
    end

    # Download this file to the specified path.
    #
    # @param [String] path The path to write the file.
    def download(path = nil)
      data = @api.download_file(id)
      return data.body unless path

      ::File.open(path, 'wb') do |file|
        file << data.body
      end
    end

    # Overwrite this file, using the file at the specified path
    #
    # @param [String] path The path to the file to upload.
    # @return [File] self
    def upload_version(file)
      file = ::File.new(file) unless file.is_a?(::UploadIO) or file.is_a?(::File)
      new_name = case file
      when ::UploadIO
        file.original_filename
      when File
        file.basename
      end

      response = @api.upload_version(id, file, etag, new_name )
      Box::File.new(@api, response.parsed_response['entries'].first)
    end

    def update(params)
      response = @api.update_file_info(id, params)
      Box::File.new(@api, response.parsed_response)
    end

    # Delete this item and all sub-items.
    #
    # @return [Item] self
    def delete
      response = @api.delete_file(id, etag)
      true
    end

    # Get the comments left on this file.
    #
    # @return [Array] An array of {Comment}s.
    def comments
      response = @api.get_file_comments(id)
      response.parsed_response['entries'].collect do |comment|
        Box::Comment.new(@api, comment)
      end
    end

    # Add a comment to the file.
    #
    # @return [Comment] The created comment.
    def add_comment(message)
      response = @api.add_comment(id, message)
      Box::Comment.new(@api, response.parsed_response)
    end

    def versions
      response = @api.get_file_versions(id)
      response['entries'].collect do |version|
        Box::Version.new(@api, version)
      end
    end

    def version(version_id)
      response = @api.get_file_version_info(id, version_id)
      Box::Version.new(@api, response.parsed_response)
    end

    def delete_version(version_id)
      response = @api.delete_file_version(id, version_id)
      Box::Version.new(@api, response.parsed_response)
    end

    def download_version(version_id, path = nil)
      data = @api.download_file_version(id, version_id)
      return data.body unless path

      ::File.open(path, 'wb') do |file|
        file << data.body
      end
    end

    def share( params = {} )
      response = @api.share_file( id, params )
      update_info( response.parsed_response )
    end

    def unshare( params = {} )
      response = @api.share_file( id, nil )
      update_info( response.parsed_response )
    end

    protected
    # (see Item#get_info)
    def get_info
      response = @api.get_file_info(id)
      response.parsed_response
    end
  end
end
