GPS = {}

$(function() {
    window.addEventListener('message', function(event) {
        if (event.data.type == "open") {
            GPS.SlideUp()
        }

        if (event.data.type == "close") {
            GPS.SlideDown()
        }
    });

    document.onkeyup = function (data) {
        if (data.which == 27) { // Escape key
            $.post('https://vs-polgps/escape', JSON.stringify({}));
            GPS.SlideDown()
        }
    };
});

$(document).on('click', '#submit', function(e){
    e.preventDefault();

    $.post('https://vs-polgps/GPSON');
});

$(document).on('click', '#disconnect', function(e){
    e.preventDefault();

    $.post('https://vs-polgps/GPSOFF');
});


GPS.SlideUp = function() {
    $(".container").css("display", "block");
    $(".gps-container").animate({bottom: "6vh",}, 250);
}

GPS.SlideDown = function() {
    $(".gps-container").animate({bottom: "-110vh",}, 400, function(){
        $(".container").css("display", "none");
    });
}
