'use strict';

class ApiNote {
    #id;

    constructor(id) {
        this.#id = id;
    }
    update(text) {
        const doneState = 4;
        const okStatus = 200;
        const url = `/notes/${this.#id}`;
        const request = new XMLHttpRequest();
        const loadCallback = function () {
            if (request.readyState !== doneState && request.status !== okStatus) {
                alert('Note update request has failed.');
            }
        };

        const params = new FormData();
        params.append('text', text);

        request.addEventListener('load', loadCallback);
        request.responseType = 'json';
        request.open('PATCH', url);
        request.send(params);
    }
    delete({ onSuccess }) {
        const doneState = 4;
        const okStatus = 200;
        const url = `/notes/${this.#id}`;
        const request = new XMLHttpRequest();
        const loadCallback = function () {
            if (request.readyState === doneState && request.status === okStatus) {
                onSuccess();
            } else {
                alert('Note delete request has failed.');
            }
        };

        request.addEventListener('load', loadCallback);
        request.open('DELETE', url);
        request.send();
    }
    swap(noteId) {
        const doneState = 4;
        const okStatus = 200;
        const url = `/notes/${this.#id}/swap`;
        const request = new XMLHttpRequest();
        const loadCallback = function () {
            if (request.readyState !== doneState && request.status !== okStatus) {
                alert('Request has failed.');
            }
        };

        const params = new FormData();
        params.append('note_id', noteId);

        request.addEventListener('load', loadCallback);
        request.open('PATCH', url);
        request.send(params);
    }
}
