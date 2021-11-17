@forelse($matches as $m)
    <div class="panel">
        <div class="panel-heading"><h5>{{ $m['guidelineName'] }}</h5></div>
        @foreach($m['args'] as $a)
            <button type="button" class="button-esmo"
                    href="{{sprintf(
                        "http://interactiveguidelines.esmo.org/esmo-web-app/media/data/EN/Html/GL%s/%s.html",
                        $m['guidelineID'],
                        $a['jumpto']
                    )}}">
                {{ $a['name'] }}
            </button>
        @endforeach
    </div>
@empty
    <div class="panel">
        <strong>No matching guidelines found.</strong>
    </div>
@endforelse