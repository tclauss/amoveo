
function new_keys() {
    return ec.genKeyPair();
}
var keys = new_keys();
function pubkey_64() {
    var pubPoint = keys.getPublic("hex");
    return btoa(fromHex(pubPoint));
}
function sign_tx(tx) {
    console.log("absout to sign tx");
    console.log(JSON.stringify(tx));
    sig = btoa(btoa(array_to_string(sign(tx, keys))));
    return ["signed", tx, sig, [-6]];
}
function download(data, filename, type) {
    var file = new Blob([data], {type: type});
    if (window.navigator.msSaveOrOpenBlob) // IE10+
        window.navigator.msSaveOrOpenBlob(file, filename);
    else { // Others
        var a = document.createElement("a"),
            url = URL.createObjectURL(file);
        a.href = url;
        a.download = filename;
        document.body.appendChild(a);
        a.click();
        setTimeout(function() {
            document.body.removeChild(a);
            window.URL.revokeObjectURL(url);
        }, 0);
    }
}
keys_function1();
function keys_function1() {
    var div = document.createElement("div");
    document.body.appendChild(div);
    
    var pub_div = document.createElement("div");
    div.appendChild(pub_div);

    var save_button = document.createElement("input");
    save_button.type = "button";
    save_button.value = "save keys to file";
    save_button.onclick = save_keys;
    div.appendChild(save_button);

    div.appendChild(document.createElement("br"));
    var file_selector = document.createElement("input");
    file_selector.type = "file";
    file_selector.onchange = load_keys;

    var load_text = document.createTextNode("get key from file ");
    div.appendChild(load_text);
    div.appendChild(file_selector);

    div.appendChild(document.createElement("br"));
    var new_pubkey_button = document.createElement("input");
    new_pubkey_button.type = "button";
    new_pubkey_button.value = "generate new keys";
    new_pubkey_button.onclick = new_keys_check;
    div.appendChild(new_pubkey_button);

    var new_pubkey_div = document.createElement("div");
    div.appendChild(new_pubkey_div);
    
    div.appendChild(document.createElement("br"));
    var balance_button = document.createElement("input");
    balance_button.type = "button";
    balance_button.value = "check balance";
    balance_button.onclick = update_balance;
    var bal_div = document.createElement("div");
    div.appendChild(bal_div);
    div.appendChild(balance_button);
    
    update_pubkey();

    //console.log(fromHex(toHex("abc")));
    function update_pubkey() {
        pub_div.innerHTML = ("your pubkey: ").concat(pubkey_64());
    }
    function new_keys_check() {
        //alert("this will delete your old keys. If you have money secured by this key, and you haven't saved your key, then this money will be destroyed.");
        var warning = document.createElement("h3");
        warning.innerHTML = "This will delete your old keys. If money is sent to them, it will be deleted.";
        new_pubkey_div.append(warning);
        
        var button = document.createElement("input");
        button.type = "button";
        button.value = "cancel";
        button.onclick = cancel;
        new_pubkey_div.appendChild(button);

        var button2 = document.createElement("input");
        button2.type = "button";
        button2.value = "continue";
        button2.onclick = doit;
        new_pubkey_div.appendChild(button2);

        function cancel() {
            new_pubkey_div.innerHTML = "";
        }
        function doit() {
            new_pubkey_div.innerHTML = "";
            keys = new_keys();
            update_pubkey();
            set_balance(0);
        }
    }
    function update_balance() {
        var trie_key = pubkey_64();
        var top_hash = hash(serialize_header(top_header));
        variable_public_get(["proof", btoa("accounts"), trie_key, btoa(array_to_string(top_hash))], function(x) { update_balance2(trie_key, x); });
        //var trie_key = 1;
        //variable_public_get(["proof", btoa("governance"), trie_key, btoa(array_to_string(top_hash)], function(x) { update_balance2(trie_key, x); } );
    }
    function update_balance2(trie_key, proof0) {
        console.log("update balance2");
        if (proof0[3] == "empty") {
            bal_div.innerHTML = "your balance: unknown";
        } else {
            console.log(JSON.stringify(proof0));
            console.log("trie_key is ");
            console.log(JSON.stringify(trie_key));
            var val = verify_merkle(trie_key, proof0);
            console.log(val);
            var balance = val[1] / 100000000;
            set_balance(balance);
        }
    }
    function set_balance(n) {
        bal_div.innerHTML = ("your balance: ").concat((n).toString());
        
    }
    function save_keys() {
        download(keys.getPrivate("hex"), "amoveo_light_keys", "text/plain");
    }
    function load_keys() {
        var file = (file_selector.files)[0];
        var reader = new FileReader();
        reader.onload = function(e) {
            keys = ec.keyFromPrivate(reader.result, "hex");
            update_pubkey();
            //update_balance();
        }
        reader.readAsText(file);
    }
}
