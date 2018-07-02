json.transfers @transfers['data'] do |transfer|
  json.(transfer, :amount, :date)

  json.transactions @company.transfer_transactions(transfer.id) do |transaction|
    json.(transaction, :amount, :fee, :net, :created, :type)
  end
end
