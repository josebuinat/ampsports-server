class CustomInvoiceComponents extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      cics: props.cics
    };
  }
  
  componentWillReceiveProps(nextProps) {
    this.setState({ cics: nextProps.cics });
  }

  componentDidMount() {
    this.loadVats();
  }

  loadVats() {
    axios.get('/custom_invoice_components/vat')
        .then((response) => {
          this.setState({ vatOptions: response.data })
        });
  }

  render() {
    let components = this.state.cics.map((cic, i) => {
      return(
        <div className='row' key={'cic' + i}>
          <div className='col-sm-6'>
            <div className="form-group">
              <input name='name'
                     value={cic.name}
                     onChange={(e) => this.props.handleUpdate(i, e)}
                     className='form-control'
                     required/>
            </div>
          </div>
          <div className='col-sm-2'>
            <div className="form-group">
              <input name='price'
                     className='form-control'
                     value={cic.price}
                     onChange={(e) => this.props.handleUpdate(i, e)}
                     required/>
            </div>
          </div>
          <div className='col-sm-3'>
            <div className="form-group">
              <Select
                name='vat'
                options={this.state.vatOptions}
                isLoading={!this.state.vatOptions}
                value={cic.vat}
                clearable={false}
                onChange={(e) => this.props.handleDropDownChange(i,e)}
                required
                placeholder={I18n.t('invoices.custom_invoice_modal.vat')} />
            </div>
          </div>
          <div className='col-sm-1'>
            <a onClick={() => this.props.onDelete(cic.id)}>
              {I18n.t('invoices.custom_invoice_modal.delete_link')}
            </a>
          </div>
        </div>
      );
    });
    return(
      <div>
        {components}
      </div>
    );
  }
}
