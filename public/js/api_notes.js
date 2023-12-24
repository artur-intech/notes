'use strict';

class ApiNotes {
    add({ text, dialog, noteList }) {
        const url = '/notes';
        const request = new XMLHttpRequest();
        const params = new FormData();
        const loadCallback = function () {
            const doneState = 4;
            const okStatus = 200;

            if (request.readyState === doneState && request.status === okStatus) {
                noteList.add({ id: request.response.id, text: request.response.text, position: request.response.position });
                dialog.hide();
            } else {
                alert('New note request has failed.');
            }
        };

        params.append('text', text);
        params.append('position', noteList.nextPosition());

        request.addEventListener('load', loadCallback);
        request.responseType = 'json';
        request.open('POST', url);
        request.send(params);
    }
}
