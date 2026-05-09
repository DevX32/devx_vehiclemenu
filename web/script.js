function validatePosition(position) {
    return [
        Math.min(Math.max(position[0], 0), 1),
        Math.min(Math.max(position[1], 0), 1)
    ];
}

function createElement(html, id, xPos, yPos) {
    const element = document.createElement('div');
    element.id = id;
    element.className = 'vehicle-icon fade-in';
    element.style.cssText = `
        display: none;
        color: white;
        position: absolute;
        left: ${xPos * 100}vw;
        top: ${yPos * 100}vh;
    `;
    element.innerHTML = html;
    return element;
}

function showVehicleParts(data) {
    const [xPos, yPos] = validatePosition(data.position);
    const elementId = data.id;
    let element = document.getElementById(elementId);
    
    if (!element) {
        element = createElement(data.html, elementId, xPos, yPos);
        document.body.appendChild(element);
        
        // Fade in effect
        setTimeout(() => {
            element.style.display = 'block';
        }, 10);
    } else {
        element.style.left = `${xPos * 100}vw`;
        element.style.top = `${yPos * 100}vh`;
    }
    
    // Remove existing click listeners
    element.replaceWith(element.cloneNode(true));
    element = document.getElementById(elementId);
    
    // Add click listener
    element.addEventListener('click', function() {
        fetch(`http://devx_vehiclemenu/VehicleMenu`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json; charset=UTF-8',
            },
            body: JSON.stringify({
                id: data.id,
            })
        });
    });
}

function closeUI() {
    document.body.innerHTML = '';
}

function removeElement(id) {
    const element = document.getElementById(id);
    if (element) {
        element.remove();
    }
}

window.addEventListener("message", function (event) {
    const data = event.data;
    switch (data.action) {
        case 'visible':
            showVehicleParts(data);
            break;
        case 'close':
            closeUI();
            break;
        case 'bonnet':
            removeElement('bonnet');
            break;
    }
});
