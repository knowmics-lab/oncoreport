'use strict';

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

const debouncedResize = debounce((e) => {
  const container = e.target.closest('.table-responsive-container');
  e.target.removeEventListener("scroll", scrollListener);
  if (e.target.clientWidth < e.target.scrollWidth) {
    container.classList.add('with-scroll');
    container.style.setProperty('--end-opacity', '1');
    container.style.setProperty('--scroll-height', `${e.target.offsetHeight - e.target.clientHeight}`);
    e.target.addEventListener("scroll", scrollListener);
  } else {
    container.classList.remove('with-scroll');
    container.style.setProperty('--start-opacity', '0');
    container.style.setProperty('--end-opacity', '0');
  }
}, 100);

const resizeObserver = new ResizeObserver(entries => {
  entries.forEach(debouncedResize)
});

[...document.querySelectorAll('.table-responsive-container > .table-responsive')].forEach(
  (container) => {
    resizeObserver.observe(container);
  }
);