# Link Exploring Bot 🤖

(version en español aquí: [README_es.md](README_es.md))

This project is only a little AWS Lambda function that validates the links exported from Delicious and sends by email those that are still active.

Since the formerly great service [Delicious](https://del.icio.us) is now sunsetting :(, I exported all the links I had there to a JSON file (from Delicious itself which, at the moment of writing this - July 2024 - is still active but has an SSL certificate error that prevents access T-T) and import said file into a MongoDB database.

After that, this little lambda, written in Ruby, springs into action and connects to the MongoDB database, searches links from the same date (month and day) as the current day, tries to connect to each one, and sends me an email containing those to which it could successfully connect, so I can manually check them and (eventually) add them to another service. It also marks those it has checked each day, and if it could connect to them or not, so that they are not sent again in the future and, eventually, to filter them and do something with the data.

I'm using the Faraday gem for doing HTTP requests; it's a fairly basic usage but good enough for this little project (b'-')b

**Issues**

The official MongoDB driver for Ruby requires native extensions, and to use RubyGems with AWS Lambda they have to be included together with the uploaded code bundle (in vendor/bundle), so you need to compile the native extensions for the AWS Lambda OS, which is not the same I'm using in my local workstation 😅.

Fortunately, it can all be solved with Docker and a pre-made image:

````
docker run -it --rm -v "$PWD":/var/task lambci/lambda:build-ruby2.7 bash
````

That command 👆 opens a shell in a container with the same environment as that of AWS Lambda for Ruby, mounting the current directory (which should be the project directory) as a volume. Then all that is needed is to run `bundle install --path vendor/bundle` to install the RubyGems in the vendor/bundle directory, zip everything up and upload it to AWS Lambda.  
(It is also possible to directly run the `bundle install` command, like so:  `docker run -it --rm -v "$PWD":/var/task lambci/lambda:build-ruby2.7 bundle install`)

(Source: https://blog.francium.tech/using-ruby-gems-with-native-extensions-on-aws-lambda-aa4a3b8862c9)

**What's next**

Since one day this bot will finish checking all the links, we could eventually reuse it to keep checking the links of the next service I use and keep them fresh, or even offer the option to search those that are no longer active in the Wayback Machine. But... that's for the next version ;).
