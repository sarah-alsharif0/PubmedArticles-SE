Event.observe(window, 'load', function() {
        new AutoComplete('articleTitle', 'autocomplete.xqy?q=', { delay: 0.1 });
        new AutoComplete('authorLastName', 'autocomplete.xqy?q=', { delay: 0.1 });
        });