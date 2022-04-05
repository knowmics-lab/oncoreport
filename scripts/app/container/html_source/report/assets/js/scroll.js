'use strict';

const navbar = document.querySelector('header.navbar');

const scrollListener = (e) => {
  const container = e.target.closest('.table-responsive-container');
  if (e.target.scrollLeft > 0) {
    container.style.setProperty('--start-opacity', '1');
  } else {
    container.style.setProperty('--start-opacity', '0');
  }
  if ((e.target.scrollLeft + e.target.clientWidth) < e.target.scrollWidth) {
    container.style.setProperty('--end-opacity', '1');
  } else {
    container.style.setProperty('--end-opacity', '0');
  }
};

function scrollElement (scrollable, direction) {
  scrollable.scroll({
    left: scrollable.scrollLeft + direction * 150,
    behavior: 'smooth',
  });
}

function createScrollButtons (scrollable) {
  const buttonStart = document.createElement('button');
  buttonStart.classList.add('scroll-indicator-start');
  buttonStart.innerHTML = '&lArr;';
  buttonStart.addEventListener('click', () => scrollElement(scrollable, -1));
  const buttonEnd = document.createElement('button');
  buttonEnd.classList.add('scroll-indicator-end');
  buttonEnd.innerHTML = '&rArr;';
  buttonEnd.addEventListener('click', () => scrollElement(scrollable, +1));
  const container = document.createElement('div');
  container.classList.add('table-scroll-indicator');
  container.appendChild(buttonStart);
  container.appendChild(buttonEnd);
  return container;
}

const debouncedResize = debounce((e) => {
  const container = e.target.closest('.table-responsive-container');
  e.target.removeEventListener('scroll', scrollListener);
  if (e.target.clientWidth < e.target.scrollWidth) {
    if (!container.querySelector('.table-scroll-indicator')) {
      container.prepend(createScrollButtons(e.target));
    }
    container.classList.add('with-scroll');
    container.style.setProperty('--header-size', `${navbar.getBoundingClientRect().height}`);
    container.style.setProperty('--end-opacity', '1');
    container.style.setProperty('--scroll-height', `${e.target.offsetHeight - e.target.clientHeight}`);
    e.target.addEventListener('scroll', scrollListener);
  } else {
    const scrollIndicator = container.querySelector('.table-scroll-indicator');
    if (scrollIndicator) scrollIndicator.remove();
    container.classList.remove('with-scroll');
    container.style.setProperty('--start-opacity', '0');
    container.style.setProperty('--end-opacity', '0');
  }
}, 100);

const resizeObserver = new ResizeObserver(entries => {
  entries.forEach(debouncedResize);
});

[...document.querySelectorAll('.table-responsive-container > .table-responsive')].forEach(
  (container) => {
    resizeObserver.observe(container);
  },
);