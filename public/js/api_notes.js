'use strict';

class ApiNotes {
    add({ text, position, onSuccess }) {
        const url = '/notes';
        const request = new XMLHttpRequest();
        const onLoad = function () {
            const doneState = 4;
            const okStatus = 200;

            if (request.readyState === doneState && request.status === okStatus) {
                const note = request.response;
                onSuccess(note);
            } else {
                alert('New note request has failed.');
            }
        };

        const params = new FormData();
        params.append('text', text);
        params.append('position', position);

        request.addEventListener('load', onLoad);
        request.responseType = 'json';
        request.open('POST', url);
        request.send(params);
    }
    fetch({ onSuccess }) {
        const url = '/notes';
        const request = new XMLHttpRequest();
        const loadCallback = function () {
            const doneState = 4;
            const okStatus = 200;
            const forbiddenStatus = 403;

            if (request.readyState === doneState) {
                switch (request.status) {
                    case okStatus:
                        onSuccess(request.response);
                        break;
                    case forbiddenStatus:
                        location.reload();
                        break;
                    default:
                        break;
                }
            } else {
                alert('Request has failed.');
            }
        };

        request.addEventListener('load', loadCallback.bind(this));
        request.responseType = 'json';
        request.open('GET', url);
        request.send();
    }
}
