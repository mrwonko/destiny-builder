package main

import (
	"crypto/rand"
	"encoding/base64"
	"fmt"
	"log"
	"net/url"
)

type userToken string

func login(conf *config) (userToken, error) {
	randState := make([]byte, 32)
	_, err := rand.Read(randState)
	if err != nil {
		return "", fmt.Errorf("failed to generate random state token: %s", err)
	}
	randState64 := base64.URLEncoding.EncodeToString(randState)
	reqURL := url.URL{
		Scheme: "https",
		Host:   "www.bungie.net",
		Path:   "/en/oauth/authorize",
		RawQuery: url.Values{
			"response_type": {"code"},
			"client_id":     {conf.ClientID},
			"state":         {randState64},
		}.Encode(),
	}
	log.Printf("please visit %s to log in", reqURL.String())
	return "", nil
}
