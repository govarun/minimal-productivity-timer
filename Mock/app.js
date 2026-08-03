const companion = document.querySelector('#companion');
const progressRing = document.querySelector('#progressRing');
const timeText = document.querySelector('#timeText');
const goalForm = document.querySelector('#goalForm');
const goalInput = document.querySelector('#goalInput');
const goalDisplay = document.querySelector('#goalDisplay');
const durationChips = [...document.querySelectorAll('[data-minutes]')];
const customMinutes = document.querySelector('#customMinutes');
const customMinutesControl = customMinutes.closest('.custom-minutes');
const killButton = document.querySelector('#killButton');
const stateButtons = [...document.querySelectorAll('[data-state]')];

const states = {
  quiet: { time: '35m', progress: 22 },
  ten: { time: '10m', progress: 71 },
  five: { time: '5m', progress: 89 },
  bell: { time: '0m', progress: 100 }
};

let activeState = 'quiet';
let currentGoal = 'Finish the Bell overlay mock';
let selectedMinutes = 35;
let dragging = false;
let dragOffset = { x: 0, y: 0 };

function setState(name) {
  const state = states[name];
  activeState = name;
  companion.dataset.phase = name;
  progressRing.style.strokeDashoffset = String(100 - state.progress);
  timeText.textContent = state.time;
  stateButtons.forEach(button => button.classList.toggle('active', button.dataset.state === name));
}

stateButtons.forEach(button => button.addEventListener('click', () => setState(button.dataset.state)));

goalDisplay.addEventListener('click', () => {
  goalInput.value = currentGoal;
  setState('bell');
});

durationChips.forEach(chip => chip.addEventListener('click', () => {
  selectedMinutes = Number(chip.dataset.minutes);
  states.quiet.time = `${selectedMinutes}m`;
  durationChips.forEach(item => item.classList.toggle('active', item === chip));
  customMinutesControl.classList.remove('active');
}));

customMinutes.addEventListener('input', () => {
  const value = Number(customMinutes.value);
  if (!Number.isFinite(value) || value < 5 || value > 240) return;
  selectedMinutes = value;
  states.quiet.time = `${selectedMinutes}m`;
  durationChips.forEach(chip => chip.classList.remove('active'));
  customMinutesControl.classList.add('active');
});

goalForm.addEventListener('submit', event => {
  event.preventDefault();
  const goal = goalInput.value.trim();
  if (!goal) return;
  currentGoal = goal;
  goalDisplay.innerHTML = `<b>Goal:</b> ${escapeHTML(goal)}`;
  goalInput.value = '';
  setState('quiet');
});

killButton.addEventListener('click', () => {
  companion.classList.add('is-killed');
});

companion.addEventListener('pointerdown', event => {
  if (event.target.closest('button, input, select')) return;
  const rect = companion.getBoundingClientRect();
  dragging = true;
  dragOffset = { x: event.clientX - rect.left, y: event.clientY - rect.top };
  companion.setPointerCapture(event.pointerId);
});

companion.addEventListener('pointermove', event => {
  if (!dragging) return;
  const x = Math.max(8, Math.min(window.innerWidth - companion.offsetWidth - 8, event.clientX - dragOffset.x));
  const y = Math.max(38, Math.min(window.innerHeight - companion.offsetHeight - 8, event.clientY - dragOffset.y));
  companion.style.left = `${x}px`;
  companion.style.top = `${y}px`;
  companion.style.right = 'auto';
});

companion.addEventListener('pointerup', event => {
  dragging = false;
  companion.releasePointerCapture(event.pointerId);
});

function escapeHTML(value) {
  const node = document.createElement('span');
  node.textContent = value;
  return node.innerHTML;
}

setState('quiet');
