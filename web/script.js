function validatePosition(position) {
    return [
        Math.min(Math.max(position[0], 0), 1),
        Math.min(Math.max(position[1], 0), 1)
    ];
}

function showNUIMode(data) {
    const [xPos, yPos] = validatePosition(data.position);
    if (!$(`#${data.id}`).length) {
        $('body').append(`
            <p id="${data.id}" style="
                display: none;
                color: white;
                position: absolute;
                left: ${xPos * 100}vw;
                top: ${yPos * 100}vh;">
                ${data.html}
            </p>`);
        $(`#${data.id}`).fadeIn(500);
    } else {
        $(`#${data.id}`).css({
            left: `${xPos * 100}vw`, 
            top: `${yPos * 100}vh` 
        });
    }
    $(`#${data.id}`).off().click(function () {
        $.post(`http://devx_vehiclemenu/VehicleMenu`, JSON.stringify({
            id: data.id,
        }));
    });
}

window.addEventListener("message", function (event) {
    let data = event.data;
    switch (data.action) {
        case 'show':
            showNUIMode(data);
        break;
        case 'close':
            $('body').html('');
        break;
        case 'bonnet':
            $("#bonnet").remove();
        break;
    }
});
