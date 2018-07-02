class CustomInvoiceComponentsContainer extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      showForm: false,
      idCounter: 0,
      cics: [ { id: 0, name: '', vat: null, price: 0 }]
    }
  }

  onCICAdd() {
    this.setState({ cics: this.state.cics.concat([{ id: ++this.state.idCounter,
                                                    name: '',
                                                    vat: null,
                                                    price: 0 }]) });
  }

  onDelete(id) {
    let filtered = this.state.cics.filter((cic) => {
      if (cic.id != id) return cic;
    });
    this.setState({ cics: filtered });
  }

  handleUpdate(i, e) {
    let cics = this.state.cics
    cics[i][e.target.name] = e.target.value;
    this.setState({ cics: cics });
  }

  handleDropDownChange(i, e) {
    let cics = this.state.cics
    cics[i]['vat'] = e.value;
    this.setState({ cics: cics });
  }

  components() {
    return this.state.cics;
  }

  render() {
    return(
      <div>
        <div className='row'>
          <div className='col-sm-6'>
            <div className="form-group">
              { I18n.t('invoices.custom_invoice_modal.table_head_name') }
            </div>
          </div>
          <div className='col-sm-2'>
            <div className="form-group">
              { I18n.t('invoices.custom_invoice_modal.table_head_price') }
            </div>
          </div>
          <div className='col-sm-2'>
            <div className="form-group">
              { I18n.t('invoices.custom_invoice_modal.table_head_vat') }
            </div>
          </div>
          <div className='col-sm-2'>
          </div>
        </div>
        <CustomInvoiceComponents cics={this.state.cics}
                                 onDelete={this.onDelete.bind(this)}
                                 handleDropDownChange={this.handleDropDownChange.bind(this)}
                                 handleUpdate={this.handleUpdate.bind(this)}/>
        <Button onClick={this.onCICAdd.bind(this)}>
          {I18n.t('invoices.custom_invoice_modal.add_custom_component')}
        </Button>
      </div>
    );
  }
}
