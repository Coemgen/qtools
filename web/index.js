function main() {
    lazyload();

    const posts = Array.from(document.querySelectorAll('article'))
        .filter(element => element.querySelector(':scope > div > div >.text'))
        .map(element => ({
            id: element.id,
            text: element.querySelector(':scope > div > div >.text').textContent,
        }));

    initSearch(posts);
}

function initSearch(posts) {
    const searchElement = document.querySelector('input[type=search]');
    searchElement.oninput = () => {
        const value = searchElement.value;

        const keywordInText = value === value.toLowerCase()
            ? text => text
                .toLowerCase()
                .includes(value)
            : text => text.includes(value);

        const ids = posts
            .filter(p => p.text && keywordInText(p.text))
            .map(p => p.id);

        applyFilter(ids);
        if (value == '')
            setParams({});
        else
            setParams({q: value});
    };

    const postLines = posts
        .filter(p => p.text)
        .map(p => ({
            id: p.id,
            lines: p
                .text
                .split('\n')
                .map(t => t.trim().replace(/[.?]/g, ''))
        }));

    const result = {};
    for (const post of postLines) {
        for (const line of post.lines) {
            if (line == '')
                continue;
            if (!result[line])
                result[line] = new Set();
            result[line].add(post.id);
        }
    }
    const resultList = Object
        .keys(result)
        .map(k => ({line: k, ids: result[k]}))
        .filter(a => a.ids.size > 2);

    resultList.sort((a, b) => b.ids.size - a.ids.size);
    const datalist = document.querySelector('#hints');
    datalist.innerHTML = resultList
        .map(i => `<option label="${i.ids.size}">${i.line}</option>`)
        .join('\n');

    const query = getParams(location.search);
    if ('q' in query) {
        searchElement.value = query.q;
        searchElement.oninput();
    }
}

function applyFilter(ids) {
    let count = 0;
    for (const element of Array.from(document.querySelectorAll('article'))) {
        if (ids.includes(element.id)) {
            element.hidden = false;
            count++;
        } else {
            element.hidden = true;
        }
    }
    document.querySelector('#count').textContent = `${count}`;
    for (const h3 of Array.from(document.querySelectorAll('main .sticky'))) {
        const section = h3.nextElementSibling;
        h3.hidden = Array.from(section.children).every(c => c.hidden);
    }
}

function toggleDialog(id) {
    if (!id) {
        document.querySelector('.dialog.open').classList.remove('open');
    } else {
        const dialog = document.querySelector(`.dialog#${id}`);
        dialog.classList.toggle('open');
    }
}

const tag = (name, attributes) => {
    const element = document.createElement(name);
    if(attributes) {
        for(const attribute of Object.keys(attributes)) {
            element.setAttribute(attribute, attributes[attribute]);
        }
    }
    return element;
};
tag.fromString = string => {
    const wrapper = document.createElement('div');
    wrapper.innerHTML = string;
    return wrapper.firstElementChild;
};
const getParams = query => {
    if (!query) {
        return { };
    }

    return (/^[?#]/.test(query) ? query.slice(1) : query)
        .split('&')
        .reduce((params, param) => {
            let [ key, value ] = param.split('=');
            params[key] = value ? decodeURIComponent(value
                // .replace(/\+/g, ' ')
            ) : '';
            return params;
        }, { });
};
const setParams = params => {
    if(Object.keys(params).length) {
        const value = Object.keys(params)
            .map(k => `${k}=${encodeURIComponent(params[k]
                // .replace(/ /g, '+')
            )}`)
            .join('&');

        history.replaceState({}, null, `?${value}`);
    } else {
        history.replaceState({}, null, `?`);
    }
};

document.addEventListener('DOMContentLoaded', main, false);