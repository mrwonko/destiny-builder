package main

import (
	"log"
)

func main() {
	conf, err := configFromEnv()
	if err != nil {
		log.Fatal(err)
	}
	userToken, err := login(conf)
	if err != nil {
		log.Fatal(err)
	}
	log.Printf("user token: %q", userToken)
}
