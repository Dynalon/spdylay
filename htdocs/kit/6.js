if (typeof jQuery == "function") {
    $(document).ready( function () {
        // Tabelle 3 automatisch korrigieren
        $(".tabelle3:not(.dummy)").attr({"cellspacing": "0", "cellpadding": "0"})
        $(".tabelle3:not(.dummy) tr").css("cursor", "pointer")
        $(".tabelle3:not(.dummy) tr").mouseenter( function () { $(this).addClass("hover") });
        $(".tabelle3:not(.dummy) tr").mouseleave( function () { $(this).removeClass("hover") });
        $(".tabelle3:not(.dummy) tr").removeClass("grey");
        $(".tabelle3:not(.dummy) td:has(a)").addClass("link");
        $(".tabelle3:not(.dummy) td:has(a)").removeClass("normal");
        $(".tabelle3:not(.dummy) td:has(a)").removeAttr("onclick");
        $(".tabelle3:not(.dummy)").each( function() {
            $(this).find("tr:not(:has(th)):odd").addClass("grey");
        })
        $(".tabelle3:not(.dummy) td a:has(img)").css({"background-image": "none", "padding": "0"});
        // H4 automatisch korrigieren
        $("h4:not(:has(span.headline-text))").each( function() {
            $(this).html('<span class="headline-text">' + $(this).html() + '</span>')
        })
        // Externe Links als solche kennzeichnen
        $("#middle-row a[href*='://']:not(:has(img)):not(.dummy), #right-row a[href*='://']:not(:has(img)):not(.dummy)").each( function() {
            href = $(this).attr("href")
            host = href.split(/\/+/g)[1]
            if (host != location.host) {
                if ((!$(this).attr("target")) && (host.indexOf('.kit.edu') == -1)) $(this).attr("target", "_blank")
                if ($(this).attr("title"))
                    $(this).attr("title", $(this).attr("title") + " (externer Link: " + href + ")");
                else
                    $(this).attr("title", "externer Link: " + href);
                $(this).append('&nbsp;<img class="external_link_symbol" src="/img/intern/icon_external_link.gif" />')
            }
        })
        $(".external_link_symbol").css({"float": "none", "margin": "0"})
        // Floatende Bilder im Text mit Abstand versehen
        $(".text img").each( function() {
            if (($(this).css("float") == 'left') && (parseInt($(this).css("margin-right")) == 0)) {
                $(this).css("margin-right", "6px")
            }
            if (($(this).css("float") == 'right') && (parseInt($(this).css("margin-left")) == 0)) {
                $(this).css("margin-left", "6px")
            }
            if ($(this).attr("longDesc") && ($(this).attr("longDesc") != '')) {
                if (($(this).attr("align")) || ($(this).css("float") != 'none')) {
                    if ($(this).css("float") != 'none') float_side = $(this).css("float")
                    if ($(this).attr("align")) float_side = $(this).attr("align")
                    floater = 'float:' + float_side + ';margin-left: ' + $(this).css("margin-left") + ';margin-right: ' + $(this).css("margin-right")
                    $(this).wrap('<div style="width:' + $(this).attr("width") + 'px;' + floater + '"></div>')
                    $(this).attr("align", "")
                }
                else {
                    $(this).wrap('<span style="padding:6px;display:inline-block;width:' + $(this).attr("width") + 'px"></span>')
                }
                $(this).after('<br><span style="font-size:0.9em">' + $(this).attr("longDesc") + '</span>')
            }
        })
        $(".text img[align=left]").each( function() {
            if (parseInt($(this).css("margin-right")) == 0) {
                $(this).css("margin-right", "6px")
            }
        })
        $(".text img[align=right]").each( function() {
            if (parseInt($(this).css("margin-left")) == 0) {
                $(this).css("margin-left", "6px")
            }
        })
        // Google Analytics ausschaltbar machen
        if ((typeof(_gaq) != "undefined") && (typeof(gmsGAOptState) != "undefined")) {
            $("#footer-content").append('<span class="footer-right" style="border-top-left-radius:5px; border-bottom-right-radius:5px; background-color:#d4defc; margin-top:1px;margin-left: 1em;height:21px"><img id="checkGAActive" style="cursor:pointer; vertical-align:middle" src=""><a href="//www.kit.edu/impressum.php#Google_Analytics" target="GA_Info" title="Information Google Analytics"><img src="//www.kit.edu/img/intern/info.png"  style="vertical-align:middle; margin-left:5px; margin-right:3px"></a></span><script type="text/javascript">gmsInitGASwitch(\'checkGAActive\', \'.kit.edu\')</script>')
            $(".footer-right").css("margin-left", "1em")
        }
        // für Druckausgabe die Infoboxen hinter den Content in unsichtbares DIV kopieren
        // im Print-Stylesheet wird #right-row unsichtbar, dafür #print_infobox sichtbar
        $("#middle-row").append('<div id="print_infobox"></div>')
        $("#print_infobox").css("display", "none")
        $("#print_infobox").append($("div#right-row").html())
    })
}

function changeImg(imgName, imgSrc) {
        document[imgName].src = imgSrc;
        return true;
    }

    function resize_window() {
        document.getElementById('wrapper').style.height = parseInt( document.body.clientHeight) + 'px';
    }

    function noSpam() {
        var a = document.getElementsByTagName("a");
        for (var i = 0; i < a.length; i++) {
            if ( (a[i].href.search(/emailform\b/) != -1) && (a[i].className.search(/force_form\b/) == -1) ) {
                var nodes = a[i].childNodes;
                var email = '';
                for (var j = 0; j < nodes.length; j++) {
                        if (nodes[j].innerHTML) {
                            if (nodes[j].className.search(/caption/) == -1) {
                                email += nodes[j].innerHTML; 
                            }
                        } else {
                            email += nodes[j].data; 
                        }
                }
                email = email.replace(/\u00a0/g, ' '); // &nbsp; in Leerzeichen wandeln
                email = email.replace(/\s/g, '.');
                email = email.replace(/∂/g, '@');
                // a[i].innerHTML = email;
                if (email.search(/@/) != -1) a[i].href = "mailto:" + email;
            }
        }
    }

    function remove_liststyle() {
        if (document.getElementById("right-row")) {
            var lis = document.getElementById("right-row").getElementsByTagName("li");
            for(i=0;i<lis.length;i++) {
                if (lis[i].firstChild.nodeName.toUpperCase() == 'A' ) {
                    lis[i].firstChild.style.backgroundImage = 'none';
                    lis[i].firstChild.style.paddingLeft ='0';
                }
            }
        }
    }
 
    function collapseFAQ() {
        spans = new Array();
        spans = document.getElementsByTagName("p");
        for(i=0; i<spans.length; i++) {
            if (spans[i].id == '') {
                if ((spans[i].className == 'faq_question') || (spans[i].className == 'faq_answer')) {
                    spans[i].id = 'FAQ'; // für IE
                    spans[i].setAttribute('name', 'FAQ'); // für FF
                }
            }
        }
        spans = document.getElementsByTagName("span");
        for(i=0; i<spans.length; i++) {
            if (spans[i].id == '') {
                if ((spans[i].className == 'faq_question') || (spans[i].className == 'faq_answer')) {
                    spans[i].id = 'FAQ'; // für IE
                    spans[i].setAttribute('name', 'FAQ'); // für FF
                }
            }
        }
        spans = document.getElementsByTagName("div");
        for(i=0; i<spans.length; i++) {
            if (spans[i].id == '') {
                if ((spans[i].className == 'faq_question') || (spans[i].className == 'faq_answer')) {
                    spans[i].id = 'FAQ'; // für IE
                    spans[i].setAttribute('name', 'FAQ'); // für FF
                }
            }
        }
        spans = document.getElementsByName("FAQ");
        var counter_question = 0;
        var counter_answer = 0;
        for(i=0; i<spans.length; i++) {
            if (spans[i].className == 'faq_question') {
                spans[i].id = 'faq_question_' + counter_question;
                counter_question++;
                spans[i].onclick = new Function("document.getElementById(this.id + '_answer').style.display = (document.getElementById(this.id + '_answer').style.display == 'none') ? 'block' : 'none';");
                spans[i].style.cursor = 'pointer';
            }
            if (spans[i].className == 'faq_answer') {
                spans[i].id = 'faq_question_' + counter_answer + '_answer';
                counter_answer++;
                spans[i].style.display = 'none';
            }
        }
    }
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 