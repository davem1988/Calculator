const inputBox = document.getElementById('input');
const expressionDiv = document.getElementById('expression');
const resultDiv = document.getElementById('result');
const preResultDiv = document.getElementById('pre-result');
const memoryIndicator = document.getElementById('memory-indicator');

const menuButton = document.getElementById('menu-button');
const appMenu = document.getElementById('app-menu');
const typeMenu = document.getElementById('type-menu');
const settingsDialog = document.getElementById('settings');


let expression = '';
let result = '';
let preResult = '';
let memory = null;

function buttonClick(event){
    const target = event.target;
    const action = target.dataset.action;
    const value = target.dataset.value;

    //console.log(action, value);
    switch (action) {
        case 'number':
            addValue(value);
            showPreResult();
            break;
        case 'clear':
            clear();
            break;
        case 'backspace':
            backspace();
            showPreResult();
            break;
        case 'memory-clear':
            memoryClear();
            break;
        case 'memory-recall':
            memoryRecall();
            showPreResult();
            break;
        case 'memory-add':
            addToMemory(1);
            break;
        case 'memory-subtract':
            addToMemory(-1);
            break;
        case 'addition':
        case 'substraction':
        case 'multiplication':
        case 'division':
            if (expression === '' && result !== ''){
                startFromResult(value);
            }else if (endsWithValue()){
                addValue(value);
            }
            break;
        case 'submit':
            submit();
            break;
        case 'negate':
            negate();
            break;
        case 'mod':
            percentage();
            break;
        case 'decimal':
            decimal(value);
            break;
        case 'parenthesis':
            parenthesis(value);
            showPreResult();
            break;
        case 'function':
            insertWithMultiply(value);
            showPreResult();
            break;
        case 'constant':
            insertWithMultiply(value);
            showPreResult();
            break;
        case 'factorial':
            insertFactorial();
            showPreResult();
            break;
        case 'operator':
            if (expression === '' && result !== '') {
                startFromResult(value);
            } else if (endsWithValue()) {
                addValue(value);
            }
            showPreResult();
            break;
    }

    updateDisplay(expression, result);

}

inputBox.addEventListener('click', buttonClick);


function addValue(value){
    if(value === '.'){
        const lastOperatorIndex = expression.search(/[+\-*/]/);
        const lastDecimalIndex = expression.lastIndexOf('.');
        const lastNumberIndex = Math.max(
            expression.lastIndexOf('+'),
            expression.lastIndexOf('-'),
            expression.lastIndexOf('*'),
            expression.lastIndexOf('/'),
        );

        if((lastDecimalIndex < lastOperatorIndex || lastDecimalIndex < lastNumberIndex || lastDecimalIndex === -1) && (expression === '' || expression.slice(lastNumberIndex +1).indexOf('-') === -1)){
            expression += value;
        }
    
    } else {
        expression += value;
    } 
}

function showPreResult(){
    preResult = expression === '' ? '' : evaluateExpression();
    preResultDiv.textContent = preResult;
}

function updateDisplay(expression, result){
    expressionDiv.textContent = expression;
    resultDiv.textContent = result;
    preResultDiv.textContent = preResult;
}

function startFromResult(value){
    expression += result + value;
}

function backspace(){
    if (expression === '' && String(result).trim() !== '') {
        expression = String(result);
        result = '';
    }

    expression = expression.slice(0, -1);

    if (expression === '') {
        preResult = '';
    }
}

function clear(){
    expression = '';
    result = '';
    preResult = '';
}

function currentNumber(){
    if (expression !== '') {
        const value = evaluateExpression();
        return typeof value === 'number' ? value : null;
    }

    const parsed = Number(result);
    return String(result).trim() !== '' && Number.isFinite(parsed) ? parsed : null;
}

function addToMemory(sign){
    const value = currentNumber();
    if (value === null) return;

    const next = parseFloat(((memory ?? 0) + sign * value).toFixed(10));
    memory = next === 0 ? null : next;
    saveMemory();
    updateMemoryIndicator();
}

function memoryRecall(){
    if (memory === null) return;

    const text = String(memory);
    const last = expression.slice(-1);
    if (expression === '' || '+-*/('.includes(last)) {
        expression += text;
    } else {
        expression = text;
    }
    result = '';
}

function memoryClear(){
    memory = null;
    saveMemory();
    updateMemoryIndicator();
}

function updateMemoryIndicator(){
    memoryIndicator.hidden = memory === null;
}

function saveMemory(){
    localStorage.setItem('calculator-memory', memory === null ? '' : String(memory));
}

function loadMemory(){
    const saved = localStorage.getItem('calculator-memory');
    const parsed = Number(saved);
    memory = saved && Number.isFinite(parsed) ? parsed : null;
    updateMemoryIndicator();
}

function submit(){
    result = evaluateExpression();
    expression = '';
    preResult = '';
}

function prepareExpression(value) {
    return replaceFactorials(value).replaceAll('π', 'Math.PI');
}

function replaceFactorials(value) {
    let output = value;
    let index = output.indexOf('!');

    while (index !== -1) {
        const head = output.slice(0, index);
        const tail = output.slice(index + 1);
        let start = head.length - 1;

        if (head[start] === ')') {
            let depth = 1;
            start--;
            while (start >= 0 && depth > 0) {
                if (head[start] === ')') depth++;
                if (head[start] === '(') depth--;
                start--;
            }
            start++;
        } else {
            while (start >= 0 && /[\d.π]/.test(head[start])) start--;
            start++;
        }

        const body = head.slice(start);
        if (body === '') break;
        output = head.slice(0, start) + `factorial(${body})` + tail;
        index = output.indexOf('!');
    }

    return output;
}

function evaluateExpression() {
    try {
        const evalResult = eval(prepareExpression(expression));
        if (typeof evalResult !== 'number' || isNaN(evalResult) || !isFinite(evalResult)) {
            return ' ';
        }
        return parseFloat(evalResult.toFixed(settings.decimals));
    } catch {
        return ' ';
    }
}

function negate(){
    if(expression === '' && result !== ''){
        result = -result;

    }else if (!expression.startsWith('-') && expression !== ''){
        expression = '-' + expression;
    }else if (expression.startsWith('-')){
        expression = expression.slice(1);
    }
}

function percentage(){
    if (expression !== ''){
        result = evaluateExpression();
        expression = '';
        if(!isNaN(result) && isFinite(result)){
            result /= 100;
        } else {
            result = '';
        }
    }else if (result !== ''){
        result = parseFloat(result) / 100;
    }
}

function decimal(value){
    if(!expression.endsWith('.') && !isNaN(expression.slice(-1))){
        addValue(value);
    }
}

function toRadians(x) {
    return settings.angleUnit === 'deg' ? x * Math.PI / 180 : x;
}

function sin(x) { return Math.sin(toRadians(x)); }

function cos(x) { return Math.cos(toRadians(x)); }

function tan(x) { return Math.tan(toRadians(x)); }

function log(x) { return Math.log10(x); }

function ln(x) { return Math.log(x); }

function sqrt(x) { return Math.sqrt(x); }

function factorial(n) {
    if (n < 0 || !Number.isInteger(n)) return NaN;
    let total = 1;
    for (let i = 2; i <= n; i++) total *= i;
    return total;
}

function endsWithValue() {
    return /[\d)π!]/.test(expression.slice(-1));
}

function insertWithMultiply(value) {
    const last = expression.slice(-1);
    if (expression === '' || '+-*/('.includes(last)) {
        expression += value;
    } else if (endsWithValue()) {
        expression += '*' + value;
    }
}

function parenthesis(value) {
    const openCount = (expression.match(/\(/g) || []).length;
    const closeCount = (expression.match(/\)/g) || []).length;

    if (value === '(') {
        insertWithMultiply('(');
    } else if (openCount > closeCount && endsWithValue()) {
        expression += ')';
    }
}

function insertFactorial() {
    if (endsWithValue() && !expression.endsWith('!')) {
        expression += '!';
    }
}


// Settings

const settings = {
    mode: 'simple',
    angleUnit: 'deg',
    decimals: 2,
    autoUpdate: true,
};

const updateStatus = document.getElementById('update-status');
const autoUpdateInput = document.getElementById('auto-update');
menuButton.addEventListener('click', (event) => {
    event.stopPropagation();
    const willOpen = appMenu.hasAttribute('hidden');
    closeMenus();
    if (willOpen) {
        appMenu.hidden = false;
        menuButton.setAttribute('aria-expanded', 'true');
    }
});
appMenu.addEventListener('click', (event) => {
    const menuAction = event.target.dataset.menu;
    const type = event.target.dataset.type;
    if (menuAction === 'settings') {
        closeMenus();
        settingsDialog.showModal();
    }
    if (menuAction === 'type') {
        const open = typeMenu.hasAttribute('hidden');
        typeMenu.hidden = !open;
        event.target.setAttribute('aria-expanded', String(open));
    }
    if (type) {
        applyMode(type);
        closeMenus();
    }
});
document.addEventListener('click', (event) => {
    if (!event.target.closest('#topbar')) closeMenus();
});
document.addEventListener('keydown', (event) => {
    if (event.key === 'Escape') closeMenus();
    if (event.key !== 'Backspace' || event.target.closest('input, textarea, select')) return;

    event.preventDefault();
    backspace();
    showPreResult();
    updateDisplay(expression, result);
});
function closeMenus() {
    appMenu.hidden = true;
    typeMenu.hidden = true;
    menuButton.setAttribute('aria-expanded', 'false');
}
function applyMode(mode) {
    settings.mode = mode;
    document.body.dataset.mode = mode;
    document.querySelectorAll('[data-type]').forEach((button) => {
        button.setAttribute('aria-checked', String(button.dataset.type === mode));
    });
    saveSettings();
}

document.getElementById('angle-unit').addEventListener('change', (event) => {
    settings.angleUnit = event.target.value;
    saveSettings();
    showPreResult();
});

document.getElementById('decimals').addEventListener('change', (event) => {
    settings.decimals = Number(event.target.value);
    saveSettings();
    showPreResult();
});

autoUpdateInput.addEventListener('change', () => {
    settings.autoUpdate = autoUpdateInput.checked;
    saveSettings();
    syncAutoUpdate();
    showUpdateStatus(settings.autoUpdate
        ? { state: 'idle' }
        : { state: 'disabled' });
});

if (window.updates) {
    window.updates.onStatus(showUpdateStatus);
}

function syncAutoUpdate() {
    if (window.updates) {
        window.updates.setEnabled(settings.autoUpdate !== false);
    }
}

function showUpdateStatus(status) {
    if (!settings.autoUpdate) {
        updateStatus.textContent = 'The app will not check GitHub for new releases';
        return;
    }

    if (status.state === 'available') {
        updateStatus.textContent = `Downloading version ${status.version}`;
    } else if (status.state === 'downloaded') {
        updateStatus.textContent = `Version ${status.version} installs when you quit`;
    } else if (status.state === 'current') {
        updateStatus.textContent = 'You are on the latest release';
    } else if (status.state === 'error') {
        updateStatus.textContent = 'Could not check for updates';
    } else {
        updateStatus.textContent = 'New releases download in the background and install when you quit';
    }
}

function saveSettings() {
    localStorage.setItem('calculator-settings', JSON.stringify(settings));
}

function loadSettings() {
    const saved = JSON.parse(localStorage.getItem('calculator-settings') || '{}');
    Object.assign(settings, saved);
    document.getElementById('angle-unit').value = settings.angleUnit;
    document.getElementById('decimals').value = settings.decimals;
    autoUpdateInput.checked = settings.autoUpdate !== false;
    settings.autoUpdate = autoUpdateInput.checked;
    applyMode(settings.mode);
    syncAutoUpdate();
}

loadSettings();
loadMemory();



