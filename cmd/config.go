package main

import (
	"fmt"
	"os"
	"reflect"
)

type config struct {
	ClientID string `env:"DESTINY_BUILDER_CLIENT_ID"`
	APIKey   string `env:"DESTINY_BUILDER_API_KEY"`
}

func configFromEnv() (*config, error) {
	var (
		errs errorList
		res  config
	)
	t := reflect.TypeOf(res)
	v := reflect.ValueOf(&res)
	for i := 0; i < t.NumField(); i++ {
		key := t.Field(i).Tag.Get("env")
		if key == "" {
			errs.add(fmt.Errorf("Programming error: Config struct field %d (%q) has no env struct tag", i, t.Field(i).Name))
			continue
		}
		val := os.Getenv(key)
		if val == "" {
			errs.add(fmt.Errorf("Environment variable %q not set", key))
			continue
		}
		switch t.Field(i).Type.Kind() {
		case reflect.String:
			v.Elem().Field(i).SetString(val)
		default:
			errs.add(fmt.Errorf("Programming error: Config struct field %d (%q) has unsupported type %s", i, t.Field(i).Name, t.Field(i).Type))
			continue
		}
	}
	return &res, errs.orNil()
}
