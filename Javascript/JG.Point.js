if(!window.JG)
JG = {};

JG.Bitmap = 
    function Point(settings) {

        let x = undefined;
        let y = undefined;

        function init(settings) {

            x = settings.x;
            y = settings.y;
        }

        init(settings);
    };