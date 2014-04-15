class ExcursionController < ActionController::Base
  def cors_preflight
    cors_headers
    render :text => '', :content_type => 'text/plain'
  end

  def error
    render :text => 'The requested route was not found'
  end
end
