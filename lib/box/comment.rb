require 'box/item'

module Box
  class Comment < Item
    def update(params)
      response = @api.update_comment(id, params)
      Box::Comment.new(@api, response.parsed_response)
    end

    def delete
      response = @api.delete_comment(id)
      Box::Comment.new(@api, response.parsed_response)
    end

    protected
    def get_info
      response = @api.get_comment(id)
      response.parsed_response
    end
  end
end
