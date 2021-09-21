# [Inews Poll Tracker](https://inews.co.uk/news/politics/uk-poll-tracker-latest-opinion-polls-major-political-parties-explained-1091547)

## The components

###  Poll Scraping
The program ([poll_scrape.py](https://github.com/tomsaunders98/PollTracker/blob/master/poll_scrape.py)) downloads the latest polls from the [UK Wikipedia national poll page](https://en.wikipedia.org/wiki/Opinion_polling_for_the_next_United_Kingdom_general_election#2021). The scraper includes all the data on the page, including the results of all minor parties.

The tracker is written in Python and uses Selenium to download polls and Pandas to format them. It runs daily on a Raspberry Pi 4.

### The Model
The model [poll_model.R(https://github.com/tomsaunders98/PollTracker/blob/master/poll_model.R)] is written in R, using the brms package. The actual model specifications are based on a poll model designed by [Jack Bailey](https://github.com/jackobailey/poll_tracker). The model provides an estimates for each poll. On days where more than one poll was conducted, the average of the two estimates are taken.

The model uses a dirichlet distribution to evaluate the topline estimates for each party. It weights each poll by a few factors: The date of poll, the number of people surveyed and the polling organisation which conducted the poll.
The weights for each polling organisation, or the "house effect", are not chosen in advance or static values. They change over time and adjust based on whether a polling organisation tends to overestimate a certain party's support compared to the baseline.

The model then manually interpolates the values on the days when polls weren't conducted and then exports them. (This is not usually necessary, but is important for the tracking part of the visualisation). The model also runs on a Raspberry Pi 4.

### The visualisation
The [visualisation](https://github.com/tomsaunders98/polltrack) is written in d3js, and provides a visual daily estimate for every day since the first poll of this year to the last.
The code for the visual part of the tracker is available [here](https://github.com/tomsaunders98/polltrack).
