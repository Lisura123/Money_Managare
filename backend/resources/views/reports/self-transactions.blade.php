@extends('reports.layout')

@section('content')

<div class="report-header">
  <div class="brand">Money Manager &mdash; Admin Report</div>
  <h1>Self-Transaction Report</h1>
  <div class="meta">
    <span>Period: <strong>{{ \Carbon\Carbon::parse($from)->format('d M Y') }}</strong>
      &ndash; <strong>{{ \Carbon\Carbon::parse($to)->format('d M Y') }}</strong></span>
    <span>Total Transactions: <strong>{{ $transactions->count() }}</strong></span>
    <span>Total Amount: <strong>{{ number_format($totalAmount, 2) }}</strong></span>
  </div>
</div>

@if ($transactions->isEmpty())
  <div class="no-data" style="padding: 20px; text-align:center;">
    No self-transactions found for the selected period.
  </div>
@else
  <table>
    <thead>
      <tr>
        <th>Date &amp; Time</th>
        <th>Source Card</th>
        <th>Source Showroom</th>
        <th>Destination Card</th>
        <th>Destination Showroom</th>
        <th class="right">Amount</th>
        <th>Description / Notes</th>
        <th>Admin</th>
      </tr>
    </thead>
    <tbody>
      @foreach ($transactions as $tx)
      <tr>
        <td style="white-space:nowrap;">{{ $tx->created_at->format('d M Y H:i') }}</td>
        <td>
          {{ $tx->fromCardAccount->bank_name ?? '—' }}<br>
          <span class="text-muted">&bull;&bull;&bull;&bull; {{ $tx->fromCardAccount->last_four ?? '' }}</span>
        </td>
        <td>{{ $tx->fromCardAccount->showroom->name ?? '—' }}</td>
        <td>
          {{ $tx->toCardAccount->bank_name ?? '—' }}<br>
          <span class="text-muted">&bull;&bull;&bull;&bull; {{ $tx->toCardAccount->last_four ?? '' }}</span>
        </td>
        <td>{{ $tx->toCardAccount->showroom->name ?? '—' }}</td>
        <td class="amount right" style="font-weight:700;">{{ number_format($tx->amount, 2) }}</td>
        <td class="text-muted">{{ $tx->notes ?? '—' }}</td>
        <td>{{ $tx->admin->name ?? '—' }}</td>
      </tr>
      @endforeach
      <tr class="totals-row">
        <td colspan="5"><strong>Grand Total</strong></td>
        <td class="amount right">{{ number_format($totalAmount, 2) }}</td>
        <td colspan="2"></td>
      </tr>
    </tbody>
  </table>
@endif

@endsection
