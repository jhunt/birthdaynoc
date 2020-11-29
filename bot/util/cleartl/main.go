package main

import (
	//"context"
	"fmt"
	"os"

	"github.com/dghubble/go-twitter/twitter"
	"github.com/dghubble/oauth1"
)

func main() {
	ckey := os.Getenv("TWITTER_CONSUMER_KEY")
	csec := os.Getenv("TWITTER_CONSUMER_SECRET")
	atok := os.Getenv("TWITTER_ACCESS_TOKEN")
	asec := os.Getenv("TWITTER_ACCESS_SECRET")

	ok := true
	if ckey == "" {
		fmt.Fprintf(os.Stderr, "missing required $TWITTER_CONSUMER_KEY environment variable...\n")
		ok = false
	}
	if csec == "" {
		fmt.Fprintf(os.Stderr, "missing required $TWITTER_CONSUMER_SECRET environment variable...\n")
		ok = false
	}
	if atok == "" {
		fmt.Fprintf(os.Stderr, "missing required $TWITTER_ACCESS_TOKEN environment variable...\n")
		ok = false
	}
	if asec == "" {
		fmt.Fprintf(os.Stderr, "missing required $TWITTER_ACCESS_SECRET environment variable...\n")
		ok = false
	}
	if !ok {
		os.Exit(1)
	}

	config := oauth1.NewConfig(ckey, csec)
	token := oauth1.NewToken(atok, asec)
	tw := twitter.NewClient(config.Client(oauth1.NoContext, token))

	tweets, _, err := tw.Timelines.HomeTimeline(&twitter.HomeTimelineParams{Count: 20})
	if err != nil {
		fmt.Printf("twitter oops: %s\n")
		os.Exit(2)
	}
	for _, tweet := range tweets {
		fmt.Printf("%lu) %s: %s\n", tweet.ID, tweet.User.Name, tweet.Text)
		if _, _, err := tw.Statuses.Destroy(tweet.ID, nil); err != nil {
			fmt.Printf("unable to delete [%lu]: %s\n", tweet.ID, err)
		} else {
			fmt.Printf(" ... deleted.\n")
		}
	}
	os.Exit(0)
}
