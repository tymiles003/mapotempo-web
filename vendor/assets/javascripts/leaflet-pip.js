/*
This is free and unencumbered software released into the public domain.

Anyone is free to copy, modify, publish, use, compile, sell, or
distribute this software, either in source code form or as a compiled
binary, for any purpose, commercial or non-commercial, and by any
means.

In jurisdictions that recognize copyright laws, the author or authors
of this software dedicate any and all copyright interest in the
software to the public domain. We make this dedication for the benefit
of the public at large and to the detriment of our heirs and
successors. We intend this dedication to be an overt act of
relinquishment in perpetuity of all present and future rights to this
software under copyright law.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

For more information, please refer to <http://unlicense.org/>
*/
(function(e){if("function"==typeof bootstrap)bootstrap("leafletpip",e);else if("object"==typeof exports)module.exports=e();else if("function"==typeof define&&define.amd)define(e);else if("undefined"!=typeof ses){if(!ses.ok())return;ses.makeLeafletPip=e}else"undefined"!=typeof window?window.leafletPip=e():global.leafletPip=e()})(function(){var define,ses,bootstrap,module,exports;
return (function(e,t,n){function r(n,i){if(!t[n]){if(!e[n]){var s=typeof require=="function"&&require;if(!i&&s)return s(n,!0);throw new Error("Cannot find module '"+n+"'")}var o=t[n]={exports:{}};e[n][0](function(t){var i=e[n][1][t];return r(i?i:t)},o,o.exports)}return t[n].exports}for(var i=0;i<n.length;i++)r(n[i]);return r})({1:[function(require,module,exports){
var pip = require('point-in-polygon');

function getLls(l) {
    var lls = l.getLatLngs(), o = [];
    for (var i = 0; i < lls.length; i++) o[i] = [lls[i].lng, lls[i].lat];
    return o;
}

function isPoly(l) {
    return l.feature &&
        l.feature.geometry &&
        l.feature.geometry.type &&
        ['Polygon', 'MultiPolygon'].indexOf(l.feature.geometry.type) !== -1;
}

var leafletPip = {
    bassackwards: false,
    pointInLayer: function(p, layer, first) {
        'use strict';
        if (!(layer instanceof L.GeoJSON)) throw new Error('must be L.GeoJSON');
        if (p instanceof L.LatLng) p = [p.lng, p.lat];
        if (leafletPip.bassackwards) p.reverse();

        var results = [];

        layer.eachLayer(function(l) {
            if (first && results.length) return;

//            if (isPoly(l) && getLls(l)) {
            if (getLls(l)) {
                results.push(l);
            }
        });

        return results;
    }
};

module.exports = leafletPip;

},{"point-in-polygon":2}],2:[function(require,module,exports){
module.exports = function (point, vs) {
    // ray-casting algorithm based on
    // http://www.ecse.rpi.edu/Homepages/wrf/Research/Short_Notes/pnpoly.html
    
    var x = point[0], y = point[1];
    
    var inside = false;
    for (var i = 0, j = vs.length - 1; i < vs.length; j = i++) {
        var xi = vs[i][0], yi = vs[i][1];
        var xj = vs[j][0], yj = vs[j][1];
        
        var intersect = ((yi > y) != (yj > y))
            && (x < (xj - xi) * (y - yi) / (yj - yi) + xi);
        if (intersect) inside = !inside;
    }
    
    return inside;
};

},{}]},{},[1])(1)
});
;