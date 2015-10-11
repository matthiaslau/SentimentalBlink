require 'twitter'
require 'date'
require 'net/http'
require 'blink1'

SENTIMENT_THRESHOLD_PERCENTAGE = 10

class Sentiment

  def initialize
    @positive = 0
    @neutral = 0
    @negative = 0

    @client = Twitter::REST::Client.new do |config|
      config.consumer_key    = 'DdwLZQ7RVCaP0i3Qp1zzoJr2o'
      config.consumer_secret = 'ulTkY3tpSwer0pfFsd4IE3nZlMldhubJ2KB95LaNFfYe61W00M'
    end

    Blink1.open do |blink1|
      blink1.off
    end
    @blink1 = Blink1.new
  end

  def analyse(keyword)
    texts= []
    @client.search(keyword, result_type: 'recent', since: Time.now.strftime('%Y-%m-%d')).take(500).collect do |tweet|
      #puts "#{tweet.user.screen_name}: #{tweet.text}"
      texts.push(tweet.text)
    end

    retrieve_sentiment(texts)
    show_sentiment

    puts "Negative: #{@negative}"
    puts "Neutral: #{@neutral}"
    puts "Positive: #{@positive}"
  end

  def retrieve_sentiment(texts)
    uri = URI('http://www.sentiment140.com/api/bulkClassifyJson')
    params = {:data => []}
    texts.each do |text|
      params[:data].push({:text => text})
    end

    req = Net::HTTP::Post.new uri.path
    req.body = params.to_json
    res = Net::HTTP.start(uri.host, uri.port) do |http|
      http.request req
    end

    json = JSON.parse(res.body)
    data = json['data']

    data.each do |text|
      polarity = text['polarity']
      case polarity
        when 0
          @negative += 1
        when 2
          @neutral += 1
        when 4
          @positive += 1
        else
      end
    end
  end

  def show_sentiment
    sum = @negative + @neutral + @positive
    negative_percentage = @negative/sum.to_f * 100
    positive_percentage = @positive/sum.to_f * 100

    @blink1.open

    if negative_percentage > positive_percentage && negative_percentage > SENTIMENT_THRESHOLD_PERCENTAGE
      # omg - the sentiment is negative!!!
      @blink1.fade_to_rgb(500, 255, 0, 0)
    elsif positive_percentage > negative_percentage && positive_percentage > SENTIMENT_THRESHOLD_PERCENTAGE
      # yeah - the sentiment is awesome
      @blink1.fade_to_rgb(500, 0, 255, 0)
    else
      # well... at least neutral
      @blink1.fade_to_rgb(500, 255, 255, 0)
    end

    @blink1.close
  end

end

sentiment = Sentiment.new
keywords = ARGV[0]
sentiment.analyse(keywords)
