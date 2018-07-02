let _ciModal;

class CustomInvoiceModal extends React.Component {
  constructor(props) {
    super(props);
    _ciModal = this;
    this.state = {
      show: false,
      user: null
    }
  }

  close() {
    this.setState({ show: false,
                    user: null });
  }

  open() {
    this.setState({ show: true });
  }

  submit() {
    if (!this.validate())
      return false;

    axios({
      method: 'post',
      url: `/companies/${this.props.company}/invoices`,
      data: {
        authenticity_token: this.props.form_authenticity_token,
        invoice: {
          user_id: this.state.user,
          custom_invoice_components: this.refs.componentsContainer.components()
        }
      }
    }).then((response) => {
      toastr.success(I18n.t('invoices.custom_invoice_modal.create_success'));
      window.location.reload();
    }).catch((response) => {
      toastr.error(I18n.t('invoices.custom_invoice_modal.create_fail'));
    });
  }

  validate() {
    if (!this.refs.componentsContainer.components().length) {
      toastr.error(I18n.t('invoices.custom_invoice_modal.no_cic_error'));
      return false;
    }
    if (!this.state.user) {
      toastr.error(I18n.t('invoices.custom_invoice_modal.no_user_error'));
      return false;
    }
    return true;
  }

  updateUser(e) {
    this.setState({ user: e ? e.value : null });
  }

  render() {
    return(
      <Modal show={this.state.show}
             bsSize='large'
             onHide={this.close.bind(this)}
             dialogClassName='custom-invoice-modal'
             aria-labelledby="contained-modal-title-lg">
        {this.header()}
        {this.content()}
        {this.footer()}
      </Modal>
    )
  }

  header() {
    return(
      <Modal.Header closeButton>
        <h1>{I18n.t('invoices.custom_invoice_modal.header')}</h1>
      </Modal.Header>
    );
  }

  content() {
    return(
      <Modal.Body>
        <form className='custom-invoice-form'>
          <FormGroup controlId="formBasicText">
            <Row className="clearfix">
              <Col md={12}>
                <ControlLabel>{I18n.t('invoices.custom_invoice_modal.user')}</ControlLabel>
                <RemoteSelect
                  name="user"
                  value={this.state.user}
                  changeHandler={this.updateUser.bind(this)}
                  clearable={false}
                  placeholder={I18n.t('invoices.custom_invoice_modal.user')}
                  url={'/api/companies/' + this.props.company + '/customers.json'}
                />
              </Col>
            </Row>
          </FormGroup>
          <CustomInvoiceComponentsContainer ref='componentsContainer'/>
        </form>
      </Modal.Body>

    );
  }

  footer() {
    return(
      <Modal.Footer>
        <button id='custom-invoice-add-button' className="btn btn-primary" onClick={this.submit.bind(this)}>
          {I18n.t('invoices.custom_invoice_modal.submit_button')}
        </button>
      </Modal.Footer>
    );
  }
}
