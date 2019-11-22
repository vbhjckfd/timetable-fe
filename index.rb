require 'sinatra'

get '/' do
  @title = 'Онлайн-табло львівського транспорту'
  slim :closest, :layout => :application
end

get '/api/stops/:code' do |code|
  api_url = ENV['API_URL'] || 'https://api.lad.lviv.ua'
  redirect to("#{api_url}/stops/#{stop_code}")
end

get '/stops/:code' do |code|
  slim :stop, :layout => :application
end

post '/partners/startmobile' do
  require 'nokogiri'

  xml_doc  = Nokogiri::XML(request.body.read).remove_namespaces!
  stop_code = xml_doc.xpath('//body').text.strip

  api_url = ENV['API_URL'] || 'https://api.lad.lviv.ua'
  request_url = "#{api_url}/stops/#{stop_code}"
  raw_data = %x(curl --max-time 30 --silent "#{request_url}" -H "Accept: application/json")

  begin
    data = JSON.parse(raw_data)
  rescue JSON::ParserError => e
    data = []
  end

  halt 503 if data.empty?

  timetable = {};
  data['timetable'].each do |item|
    timetable[item['route']] = [] unless timetable.key? item['route']

    timetable[item['route']] << item['time_left'] if timetable[item['route']].length < 2
  end

  result = []
  timetable.each do |key, row|
    joined_times = row.join(', ').gsub(/хв/, 'm')
    result << "#{key}: #{joined_times}"
  end

  while result.join("\n").length > 160
    result.pop
  end

  result.sort! do |x, y|
    x[0..3] <=> y[0..3]
  end

  builder = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
    xml.answer(:type => 'sync') {
      xml.body(:paid => false) {
        xml.cdata (result.count > 0) ? result.join("\n") : "Зв'язок з сервером втрачено. Працюємо над відновленням"
      }
    }
  end

  content_type 'application/xml'
  builder.to_xml
end

get '/closed-stops/1' do
  redirect to 'https://pastebin.com/raw/ED5HMjrd'
end

get '/scheme' do
  redirect to 'http://kaliberda.com/images/work/2019-05-scheme/scheme-lviv-electr-2019.pdf'
end

get '/tmp' do
  redirect to '/tmp/'
end

get '/tmp/' do
  send_file File.join(settings.public_folder, 'tmp/index.html')
end

get '/*' do
  stop_code = params['splat'].first.to_i
  pass unless stop_code

  redirect to("/stops/#{stop_code}")
end
