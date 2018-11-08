package main

import "strings"

type errorList []error

func (el *errorList) add(err error) *errorList {
	if err != nil {
		if sl, ok := err.(multiError); ok {
			for _, err := range sl {
				*el = append(*el, err)
			}
		} else {
			*el = append(*el, err)
		}
	}
	return el
}

func (el errorList) orNil() error {
	if len(el) == 0 {
		return nil
	}
	return multiError(el)
}

type multiError []error

func (me multiError) Error() string {
	res := strings.Builder{}
	for i, err := range me {
		if i > 0 {
			_, _ = res.WriteRune('\n')
		}
		_, _ = res.WriteString(err.Error())
	}
	return res.String()
}

var _ error = multiError(nil)
