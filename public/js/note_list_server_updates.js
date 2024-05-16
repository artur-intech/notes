'use strict';

class NoteListServerUpdates {
    #sseEventSrc;

    constructor() {
        this.#startListeningForServerUpdates();

        document.addEventListener('visibilitychange', () => {
            if (document.hidden) {
                this.#stopListeningForServerUpdates();
            } else {
                this.#startListeningForServerUpdates();
                this.#dispatchUpdatedEvent();
            }
        });
    }
    #startListeningForServerUpdates() {
        this.#sseEventSrc = new EventSource('/sse');
        this.#sseEventSrc.addEventListener('message', this.#onMessage.bind(this));
    }
    #stopListeningForServerUpdates() {
        this.#sseEventSrc.close();
    }
    #dispatchUpdatedEvent() {
        const event = new Event('notesUpdated');
        document.dispatchEvent(event);
    }
    #onMessage(event) {
        const parsedBody = JSON.parse(event.data);

        if (parsedBody.updated) {
            this.#dispatchUpdatedEvent();
        }
    }
}
