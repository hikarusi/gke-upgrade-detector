package p

import (
	"context"
	"fmt"
	"log"
)

// PubSubMessage is the payload of a Pub/Sub event. Please refer to the docs for
// additional information regarding Pub/Sub events.
type PubSubMessage struct {
	Data       []byte           `json:"data"`
	Attributes PubSubAttributes `json:"attributes"`
}

type PubSubAttributes struct {
	Payload string `json:"payload"`
}

func OutputLog(ctx context.Context, m PubSubMessage) error {

	// output log
	log.Print(fmt.Sprintf("GKE Upgrade start. Data: %s", string(m.Data)))
	log.Print(fmt.Sprintf("GKE Upgrade start. Payload: %s", m.Attributes.Payload))

	return nil
}