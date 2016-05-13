express = require 'express'
app = express()
request = require 'request'
Rss = require 'rss'
cheerio = require 'cheerio'

getFeed = (callback) ->
  request.get 'http://thestoutbrothers.com/locations/smyrna/beers-on-tap/', (error, res, html) ->
    return callback error if error?
    $ = cheerio.load html
    beers = $('.beer-box').map (__, el) ->
      title: $(el).find('td:nth-child(3) h5').text()
      abv: $(el).find('h5:contains(ABV)').next('p').text()
      ibu: $(el).find('h5:contains(IBU)').next('p').text()
      image: $(el).find('img').first().attr('src')
      description: $(el).find('td:nth-child(3) h5').next('p').text()
      parings: $(el).find('h5:contains(Food Pairings)').next('p').text()
    .get()
    callback null, createFeed(beers)

createFeed = (data) ->
  feed = new Rss
    title: 'Smyrna Beer Market Beer List'
    description: 'Beers On Tap'
    feed_url: 'http://beerfeed.herokuapp.com/sbm'
    custom_elements: [
      ibv: 'Alcohol By Volume'
    ,
      ibu: 'International Bitterness Units'
    ,
      thumbnail: 'Beer thumbnail'
    ]

  data.forEach (beer) ->
    feed.item
      title: beer.title
      url: 'http://thestoutbrothers.com/locations/smyrna/beers-on-tap/'
      description: beer.description
      date: new Date()
      guid: "http://thestoutbrothers.com/locations/smyrna/beers-on-tap/##{beer.title}"
      custom_elements: [
        ibv: beer.ibv
      ,
        ibu: beer.ibu
      ,
        thumbnail: beer.image
      ]
  feed

app.get '/sbm', (req, res) ->
  getFeed (error, feed) ->
    return res.json 400, 'error getting feed' if error?
    res.set('Content-Type', 'text/xml')
    res.status(200).send feed.xml()

app.listen process.env.PORT or 9000
