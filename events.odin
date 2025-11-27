package main

import "core:container/queue"

Event :: struct {
	type:    Event_Type,
	payload: Event_Payload,
}

Event_Type :: enum {
	Unlocked_Door,
	Chest_Appeared,
}


Event_Location_Payload :: struct {
	location: Vec2,
}

Event_Payload :: union {
	Event_Location_Payload,
}

Event_Callback :: proc(event: Event)

event_listeners: map[Event_Type][dynamic]Event_Callback
event_queue: queue.Queue(Event)

publish_event :: proc(type: Event_Type, payload: Event_Payload) {
	queue.enqueue(&event_queue, Event{type = type, payload = payload})
}

subscribe_event :: proc(type: Event_Type, callback: Event_Callback) {
	if type not_in event_listeners {
		event_listeners[type] = make([dynamic]Event_Callback)
	}
	append(&event_listeners[type], callback)
}

process_events :: proc() {
	for queue.len(event_queue) > 0 {
		event := queue.dequeue(&event_queue)
		if listeners, ok := event_listeners[event.type]; ok {
			for callback in listeners {
				callback(event)
			}
		}
	}
}
