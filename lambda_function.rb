require 'json'
require 'date'
require 'aws-sdk'

require 'rubygems'
require 'bundler/setup'

require 'mongo'
require 'faraday'

def generate_html_body(links)
  link_list = links.map { |link| "<li><a href='#{link[:url]}'>#{link[:title]}</a></li>" }
  return <<HERE
<p>Hola!</p>
<p>Estos son los links del archivo para el día de hoy:</p>
<ul>#{link_list.join("\n")}</ul>
<p>Disfruta!</p>
<p>-- linkbot</p>
HERE
end

def generate_text_body(links)
  link_list = links.map { |link| "#{link[:url]} - #{link[:title]}" }
  return <<HERE
Hola!
Estos son los links del archivo para el día de hoy

#{link_list.join("\n")}

Disfruta!

-- linkbot
HERE
end

def send_valid_links(links)
  return if links.empty?

  encoding = "UTF-8"
  htmlbody = generate_html_body(links)
  textbody = generate_text_body(links)
  email_spec = {
    source: ENV["SENDER"],
    destination: {
      to_addresses: [ ENV["RECIPIENT"] ],
    },
    message: {
      subject: {
        charset: encoding,
        data: "Links del archivo para hoy #{Date.today.strftime("%d/%m/%Y")}",
      },
      body: {
        html: {
          charset: encoding,
          data: htmlbody,
        },
        text: {
          charset: encoding,
          data: textbody,
        },
      },
    },
  }

  ses = Aws::SES::Client.new(region: "us-east-1")
  ses.send_email(email_spec)
end

def lambda_handler(event:, context:)
  client = Mongo::Client.new(ENV["MONGODB_URI"])
  today = Date.today
  bookmarks = client[:delicious].find({'$expr': {'$and': [
                                                   {'$eq': [{'$month': '$dateCreated'}, today.month]},
                                                   {'$eq': [{'$dayOfMonth': '$dateCreated'}, today.day]}
                                                         ]},
                                       visited: {'$exists': false}})
  valid_bookmarks = []
  visited = bookmarks.count
  bookmarks.each do |bookmark_data|
    begin
      response = Faraday.get bookmark_data['url']
      valid_bookmarks << {url: bookmark_data['url'], title: bookmark_data['title']} if response.success?
      client[:delicious].update_one(
        {_id: bookmark_data['_id']},
        {'$set': {valid: response.success?}}
      )
    rescue Faraday::Error => e
      puts "Error al acceder a #{bookmark_data['url']}: #{e}"
      client[:delicious].update_one(
        {_id: bookmark_data['_id']},
        {'$set': {valid: false}}
      )
    end
  end
  begin
    if valid_bookmarks.empty?
      puts "hoy no hay links pasados"
    else
      send_valid_links valid_bookmarks
      puts "Email sent!"
    end
    bookmarks.update_many({'$set': {visited: true}})
    { statusCode: 200, body: JSON.generate({success: true, visited: visited, valid: valid_bookmarks.size}) }
  rescue Aws::SES::Errors::ServiceError => error
    puts "Email not sent. Error message: #{error}"
    { statusCode: 500, body: "Email not sent. Error message: #{error}" }
  end
end
