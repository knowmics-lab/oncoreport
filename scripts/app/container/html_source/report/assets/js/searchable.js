'use strict';

function makeSearchable (tableContainer) {
  const table = tableContainer.querySelector('table.table');
  if (!tableContainer || !table) return;
  const parentElement = tableContainer.parentElement.classList.contains('table-responsive-container')
    ? tableContainer.parentElement
    : tableContainer;
  const searchTableBody = table.querySelector('tbody');
  if (!searchTableBody) return;
  const debouncedSearch = debounce((value) => {
    const searchValue = value.trim().toUpperCase();
    const rows = [...searchTableBody.querySelectorAll('tr')];
    rows.forEach((r) => r.classList.remove('d-none'));
    if (searchValue !== '') {
      const tdSearchCallback = (td) => !td.textContent.toUpperCase().includes(searchValue);
      rows.
        filter((r) => [...r.querySelectorAll('td')].every(tdSearchCallback)).
        forEach((r) => r.classList.add('d-none'));
    }
  });
  const searchBox = createSearchBox((e) => debouncedSearch(e.target.value));
  parentElement.before(searchBox);
}

function debounce (cb, delay = 200) {
  let timeout;

  return (...args) => {
    clearTimeout(timeout);
    timeout = setTimeout(() => {
      cb(...args);
    }, delay);
  };
}

function createSearchBox (inputCallback) {
  const searchInput = document.createElement('input');
  searchInput.classList.add('form-control', 'w-100');
  searchInput.style.paddingLeft = '2.75rem';
  searchInput.placeholder = 'Enter a text to search the table...';
  searchInput.ariaLabel = 'Enter a text to search the table...';
  searchInput.addEventListener('input', inputCallback);
  const searchInputContainer = document.createElement('div');
  searchInputContainer.classList.add('position-relative');
  searchInputContainer.innerHTML =
    `<span class="position-absolute" style="top: 0.50rem; left: 1rem;">
        <svg class="bi flex-shrink-0 me-2" width="24" height="24" role="img" aria-label="Search">
            <use xlink:href="#search-icon"/>
        </svg>
    </span>`;
  searchInputContainer.append(searchInput);
  const searchFlexContainer = document.createElement('div');
  searchFlexContainer.classList.add(
    'mb-2', 'd-flex', 'flex-row-reverse', 'justify-content-between', 'align-items-center',
  );
  searchFlexContainer.append(searchInputContainer);
  return searchFlexContainer;
}

document.querySelectorAll('[data-searchable]').forEach(makeSearchable);