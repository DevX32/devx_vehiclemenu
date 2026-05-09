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
        opacity: 0;
        color: white;
        position: absolute;
        left: ${xPos * 100}vw;
        top: ${yPos * 100}vh;
        transition: opacity 0.3s ease-out;
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
        
        const clickHandler = function() {
            fetch(`http://devx_vehiclemenu/VehicleMenu`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json; charset=UTF-8',
                },
                body: JSON.stringify({
                    id: data.id,
                })
            });
        };
        
        clickHandlers.set(elementId, clickHandler);
        element.addEventListener('click', clickHandler);
        
        requestAnimationFrame(() => {
            element.style.display = 'block';
            element.style.opacity = '0';
            requestAnimationFrame(() => {
                element.style.opacity = '1';
            });
        });
    } else {
        const currentLeft = parseFloat(element.style.left);
        const currentTop = parseFloat(element.style.top);
        const newLeft = xPos * 100;
        const newTop = yPos * 100;
        
        if (Math.abs(currentLeft - newLeft) > 0.1 || Math.abs(currentTop - newTop) > 0.1) {
            element.style.transition = 'left 0.1s ease-out, top 0.1s ease-out';
            element.style.left = `${newLeft}vw`;
            element.style.top = `${newTop}vh`;
            
            setTimeout(() => {
                element.style.transition = '';
            }, 100);
        }
    }
}

function closeUI() {
    clickHandlers.clear();
    document.body.innerHTML = '';
}

function removeElement(id) {
    const element = document.getElementById(id);
    if (element) {
        clickHandlers.delete(id);
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
