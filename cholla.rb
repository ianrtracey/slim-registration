require 'data_mapper'
require 'dm-core'
require 'dm-migrations'
require 'dm-sqlite-adapter'
require 'dm-timestamps'
require 'ostruct'


class Hash
  def self.to_ostructs(obj, memo={})
    return obj unless obj.is_a? Hash
    os = memo[obj] = OpenStruct.new
    obj.each { |k,v| os.send("#{k}=", memo[v] || to_ostructs(v, memo)) }
    os
  end
end

$config = Hash.to_ostructs(YAML.load_file(File.join(Dir.pwd, 'config.yml')))

configure do
  DataMapper::setup(:default, File.join('sqlite3://', Dir.pwd, 'development.db'))
end

class Registration
  include DataMapper::Resource

  property :id,           Serial
  property :created_at,   DateTime
  property :name,         String
  property :email,        String
  property :school,       String
  property :github,       String
  property :linkedin,     String
  property :website,      String
  property :updated_at,   DateTime
end

# class Attachment
#   include DataMapper::Resource

#   belongs_to :video

#   property :id,         Serial
#   property :created_at, DateTime
#   property :extension,  String
#   property :filename,   String
#   property :mime_type,  String
#   property :path,       Text
#   property :size,       Integer
#   property :updated_at, DateTime

#   def handle_upload(file)
#     self.extension = File.extname(file[:filename]).sub(/^\./, '').downcase
#     supported_mime_type = $config.supported_mime_types.select { |type| type['extension'] == self.extension }.first
#     return false unless supported_mime_type

#     self.filename  = file[:filename]
#     self.mime_type = file[:type]
#     self.path      = File.join(Dir.pwd, $config.file_properties.send(supported_mime_type['type']).absolute_path, file[:filename])
#     self.size      = File.size(file[:tempfile])
#     File.open(path, 'wb') do |f|
#       f.write(file[:tempfile].read)
#     end
#     FileUtils.symlink(self.path, File.join($config.file_properties.send(supported_mime_type['type']).link_path, file[:filename]))
#   end
# end

configure :development do
  DataMapper.finalize
  DataMapper.auto_upgrade!
end

before do
  headers "Content-Type" => "text/html; charset=utf-8"
end

get '/' do
  @title = 'Registration'
  haml :index
end

post '/registration/create' do
  registration = Registration.new(params[:registration])

  if registration.save
    @message = 'Registration was saved.'
  else
    @message = 'Registration was not saved.'
  end
  haml :create
end

get '/registration/new' do
  @title = 'Register'
  haml :new
end

get '/registration/list' do
  @title = 'My Registration'
  @registrations = Registration.all(:order => [:name.desc])
  haml :list
end

get '/registration/show/:id' do
  @video = Registration.get(params[:id])
  @title = @video.description
  if @video
    haml :show
  else
    redirect '/video/list'
  end
end

get '/reg-test/' do
  haml :reg_test
end

get '/video/watch/:id' do
  video = Video.get(params[:id])
  if video
    @videos = {}
    video.attachments.each do |attachment|
      supported_mime_type = $config.supported_mime_types.select { |type| type['extension'] == attachment.extension }.first
      if supported_mime_type['type'] === 'video'
        @videos[attachment.id] = { :path => File.join($config.file_properties.video.link_path['public'.length..-1], attachment.filename) }
      end
    end
    if @videos.empty?
      redirect "//show/#{video.id}"
    else
      @title = "Watch #{video.title}"
      haml :watch
    end
  else
    redirect '/video/list'
  end
end


