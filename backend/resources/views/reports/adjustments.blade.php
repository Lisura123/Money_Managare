@extends('reports.layout')

@section('content')

<div class="report-header">
  <div class="brand">Money Manager &mdash; Admin Report</div>
  <h1>Cash &amp; Card Adjustment Report</h1>
  <div class="meta">
    <span>Period: <strong>{{ \Carbon\Carbon::parse($from)->format('d M Y') }}</strong>
      &ndash; <strong>{{ \Carbon\Carbon::parse($to)->format('d M Y') }}</strong></span>
    <span>Cash Adj Total: <strong>{{ number_format($cashTotal, 2) }}</strong></span>
    <span>Card Adj Total: <strong>{{ number_format($cardTotal, 2) }}</strong></span>
  </div>
</div>

{{-- ── Cash Adjustments ─────────────────────────────────── --}}
<div class="section-title">Cash Adjustments by Showroom</div>

@forelse ($cashByShowroom as $showroomName => $adjustments)
  <div class="subsection-title">{{ $showroomName }}</div>
  <table>
    <thead>
      <tr>
        <th>Adj. Date</th>
        <th>Entry Date</th>
        <th>Staff Member</th>
        <th>Admin</th>
        <th>Reason</th>
        <th class="right">Adjusted Amount</th>
      </tr>
    </thead>
    <tbody>
      @foreach ($adjustments as $adj)
      <tr>
        <td style="white-space:nowrap;">{{ $adj->created_at->format('d M Y H:i') }}</td>
        <td>
          {{ $adj->dailyCashEntry
              ? \Carbon\Carbon::parse($adj->dailyCashEntry->entry_date)->format('d M Y')
              : '—' }}
        </td>
        <td>{{ $adj->dailyCashEntry->user->name ?? '—' }}</td>
        <td>{{ $adj->admin->name ?? '—' }}</td>
        <td class="text-muted">{{ $adj->reason }}</td>
        <td class="amount right {{ $adj->adjusted_amount >= 0 ? 'badge-in' : 'badge-out' }}">
          {{ $adj->adjusted_amount >= 0 ? '+' : '' }}{{ number_format($adj->adjusted_amount, 2) }}
        </td>
      </tr>
      @endforeach
      <tr class="subtotals-row">
        <td colspan="5"><strong>{{ $showroomName }} Cash Adj. Total</strong></td>
        <td class="amount right">
          @php $sub = $adjustments->sum('adjusted_amount'); @endphp
          {{ $sub >= 0 ? '+' : '' }}{{ number_format($sub, 2) }}
        </td>
      </tr>
    </tbody>
  </table>
@empty
  <div class="no-data">No cash adjustments for this period.</div>
@endforelse

<table style="width:auto; margin: 8px 0 20px auto;">
  <tr>
    <th>Total Cash Adjustments (All Showrooms)</th>
  </tr>
  <tr class="totals-row">
    <td class="amount right">{{ $cashTotal >= 0 ? '+' : '' }}{{ number_format($cashTotal, 2) }}</td>
  </tr>
</table>

{{-- ── Card Adjustments ─────────────────────────────────── --}}
<div class="section-title">Card Adjustments by Showroom</div>

@forelse ($cardByShowroom as $showroomName => $adjustments)
  <div class="subsection-title">{{ $showroomName }}</div>
  <table>
    <thead>
      <tr>
        <th>Adj. Date</th>
        <th>Entry Date</th>
        <th>Card Account</th>
        <th>Staff Member</th>
        <th>Admin</th>
        <th>Reason</th>
        <th class="right">Adjusted Amount</th>
      </tr>
    </thead>
    <tbody>
      @foreach ($adjustments as $adj)
      <tr>
        <td style="white-space:nowrap;">{{ $adj->created_at->format('d M Y H:i') }}</td>
        <td>
          {{ $adj->dailyCardEntry
              ? \Carbon\Carbon::parse($adj->dailyCardEntry->entry_date)->format('d M Y')
              : '—' }}
        </td>
        <td>
          @if ($adj->dailyCardEntry && $adj->dailyCardEntry->cardAccount)
            {{ $adj->dailyCardEntry->cardAccount->bank_name }}<br>
            <span class="text-muted">&bull;&bull;&bull;&bull; {{ $adj->dailyCardEntry->cardAccount->last_four }}</span>
          @else
            —
          @endif
        </td>
        <td>{{ $adj->dailyCardEntry->user->name ?? '—' }}</td>
        <td>{{ $adj->admin->name ?? '—' }}</td>
        <td class="text-muted">{{ $adj->reason }}</td>
        <td class="amount right {{ $adj->adjusted_amount >= 0 ? 'badge-in' : 'badge-out' }}">
          {{ $adj->adjusted_amount >= 0 ? '+' : '' }}{{ number_format($adj->adjusted_amount, 2) }}
        </td>
      </tr>
      @endforeach
      <tr class="subtotals-row">
        <td colspan="6"><strong>{{ $showroomName }} Card Adj. Total</strong></td>
        <td class="amount right">
          @php $sub = $adjustments->sum('adjusted_amount'); @endphp
          {{ $sub >= 0 ? '+' : '' }}{{ number_format($sub, 2) }}
        </td>
      </tr>
    </tbody>
  </table>
@empty
  <div class="no-data">No card adjustments for this period.</div>
@endforelse

<table style="width:auto; margin: 8px 0 0 auto;">
  <tr>
    <th>Total Card Adjustments (All Showrooms)</th>
  </tr>
  <tr class="totals-row">
    <td class="amount right">{{ $cardTotal >= 0 ? '+' : '' }}{{ number_format($cardTotal, 2) }}</td>
  </tr>
</table>

@endsection
