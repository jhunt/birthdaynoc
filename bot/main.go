package main

import (
	"context"
	"fmt"
	"math/rand"
	"os"
	"strconv"
	"time"

	"github.com/dghubble/go-twitter/twitter"
	"github.com/dghubble/oauth1"
	"github.com/go-redis/redis/v8"
)

func main() {
	every := 3600
	jitter := 900
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
	if s := os.Getenv("EVERY_X_SECONDS"); s != "" {
		n, err := strconv.Atoi(s)
		if err != nil {
			fmt.Fprintf(os.Stderr, "invalid value for $EVERY_X_SECONDS '%s': %s\n", s, err)
			ok = false
		}
		every = n
	}
	if s := os.Getenv("JITTER_X_SECONDS"); s != "" {
		n, err := strconv.Atoi(s)
		if err != nil {
			fmt.Fprintf(os.Stderr, "invalid value for $JITTER_X_SECONDS '%s': %s\n", s, err)
			ok = false
		}
		jitter = n
	}
	if !ok {
		os.Exit(1)
	}

	config := oauth1.NewConfig(ckey, csec)
	token := oauth1.NewToken(atok, asec)
	tw := twitter.NewClient(config.Client(oauth1.NoContext, token))

	rd := redis.NewClient(&redis.Options{
		Addr:     os.Getenv("REDIS_ADDRESS"),
		Password: os.Getenv("REDIS_PASSWORD"),
	})
	_, err := rd.Ping(context.TODO()).Result()
	if err != nil {
		fmt.Printf("redis oops: %s\n", err)
		os.Exit(2)
	}

	for {
		(func() {
			now := time.Now()
			key := "tw." + now.Format("0102")

			fmt.Printf("[checking in %s]\n", key)
			got, err := rd.BLPop(context.TODO(), 1*time.Hour, key).Result()
			if err != nil {
				fmt.Printf("redis oops (blpop): %s\n")
				return
			}

			text := got[1]
			fmt.Printf("[%s] sending '%s'\n", now, text)
			tweet, _, err := tw.Statuses.Update(text, nil)
			if err != nil {
				fmt.Printf("[%s] FAIL: %s\n", now, err)
			}
			fmt.Printf("[%s] SENT! %lu> %s: %s\n", now, tweet.ID, tweet.User.Name, tweet.Text)

			err = rd.RPush(context.TODO(), key, text).Err()
			if err != nil {
				fmt.Printf("redis oops (rpush): %s\n")
				return
			}
		})()

		n := every + rand.Int()%(jitter*2)
		time.Sleep(time.Duration(n) * time.Second)
	}
	os.Exit(0)
}
