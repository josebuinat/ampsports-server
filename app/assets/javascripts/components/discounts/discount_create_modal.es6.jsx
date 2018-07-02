// Modal for creating and editing discounts
var _discountModal;
var FormControl = ReactBootstrap.FormControl;

class DiscountCreateModal extends React.Component {
  constructor(props) {
    super(props);
    _discountModal = this;
    this.state = this.clearedState();
    this.methodOptions = [
      {value: 'percentage', label: 'percentage'},
      {value: 'fixed', label: 'fixed'}
    ]
  }

  clearedState() {
    return {
      id: null,
      value: '',
      court_type: null,
      start_date: null,
      end_date: null,
      name: '',
      method: null,
      court_surfaces: [],
      court_sports: [],
      time_limitations: [],
      show: false
    };
  }

  open(id = null) {
    this.setState({show: true});
    if (id) {
      axios.get('/api/discounts/' + id)
           .then((response) => {
             this.setState({
               id: response.data.id,
               value: response.data.value,
               court_type: response.data.court_type,
               start_date: this.stringToDate(response.data.start_date),
               end_date: this.stringToDate(response.data.end_date),
               name: response.data.name,
               method: response.data.method,
               court_surfaces: response.data.court_surfaces,
               court_sports: response.data.court_sports,
               time_limitations: response.data.time_limitations || []
             });
           });
    }
  }

  stringToDate(str) {
    if (!str)
      return null;
    return moment(str, 'YYYY/MM/DD');
  }

  close() {
    this.setState(this.clearedState());
  }

  submit() {
    url = this.state.id ? '/api/discounts/' + this.state.id : '/api/venues/' + this.props.venue_id + '/discounts';
    axios({
      method: this.state.id ? 'patch' : 'post',
      url: url,
      data: {
        authenticity_token: this.props.form_authenticity_token,
        discount: {
          name: this.state.name,
          value: this.state.value,
          method: this.state.method,
          start_date: this.state.start_date.format('YYYY-MM-DD'),
          end_date: this.state.end_date.format('YYYY-MM-DD'),
          court_sports: this.state.court_sports,
          court_type: this.state.court_type,
          court_surfaces: this.state.court_surfaces,
          time_limitations: this.state.time_limitations
        }
      }
    }).then((response) => {
      this.successMessage();
      this.setState({show: false});
      location.reload();
    }).catch((error) => {
      this.errorMessage(error);
      console.log(error);
    });
  }

  successMessage() {
    if(this.state.id) {
      toastr.success(I18n.t('venues.manage_discounts.create_modal.update_discount_success'));
    } else {
      toastr.success(I18n.t('venues.manage_discounts.create_modal.create_discount_success'));
    }
  }

  errorMessage(error) {
    if(this.state.id) {
      toastr.error(I18n.t('venues.manage_discounts.create_modal.update_discount_fail'));
    } else {
      toastr.error(I18n.t('venues.manage_discounts.create_modal.create_discount_fail'));
    }
  }

  handleChange(e) {
    this.setState({ [e.target.name]: e.target.value });
  }

  handleDropDownChange(key, e) {
    if (!e) {
      this.setState({ [key]: null });
    } else {
      value = e.length ? e.map((i) => i.value) : e.value
      this.setState({ [key]: value });
    }
  }

  handleDateChange(key, date) {
    this.setState({ [key]: date });
  }

  handleTimeLimitationsChange(time_limitations) {
    this.setState({ time_limitations: time_limitations });
  }

  render() {
    return (
      <Modal show={this.state.show}
             onHide={this.close.bind(this)}
             aria-labelledby="contained-modal-title-lg">
        {this.header()}
        {this.content()}
        {this.footer()}
      </Modal>
    );
  }

  header() {
    return(
      <Modal.Header closeButton>
        <h1>{I18n.t('venues.manage_discounts.create_modal.discount')}</h1>
      </Modal.Header>
    );
  }

  footer() {
    return(
      <Modal.Footer>
        <button className="btn btn-primary" onClick={this.submit.bind(this)}>
          {I18n.t('venues.manage_discounts.create_modal.submit')}
        </button>
      </Modal.Footer>
    );
  }

  content() {
    return(
      <Modal.Body>
        <form className='discount-form'>
          <FormGroup controlId="formBasicText">
            <Row className="clearfix">
              <Col md={12}>
                <ControlLabel>{I18n.t('venues.manage_discounts.create_modal.name')}</ControlLabel>
                <FormControl
                  type="text"
                  name="name"
                  value={this.state.name}
                  onChange={this.handleChange.bind(this)}
                  placeholder={I18n.t('venues.manage_discounts.create_modal.name')}
                />
              </Col>
            </Row>
          </FormGroup>
          <FormGroup controlId="formBasicText">
            <Row className="clearfix">
              <Col md={12}>
                <ControlLabel>{I18n.t('venues.manage_discounts.create_modal.value')}</ControlLabel>
                <FormControl
                  type="text"
                  name="value"
                  value={this.state.value}
                  onChange={this.handleChange.bind(this)}
                  placeholder={I18n.t('venues.manage_discounts.create_modal.value')}
                />
              </Col>
            </Row>
          </FormGroup>
          <FormGroup controlId="formBasicText">
            <Row className="clearfix">
              <Col md={12}>
                <ControlLabel>{I18n.t('venues.manage_discounts.create_modal.type')}</ControlLabel>
                <Select
                  name="method"
                  options={this.methodOptions}
                  isLoading={false}
                  value={this.state.method}
                  clearable={false}
                  onChange={this.handleDropDownChange.bind(this, 'method')}
                  placeholder={I18n.t('venues.manage_discounts.create_modal.type_placeholder')}
                />
              </Col>
            </Row>
          </FormGroup>
          <FormGroup controlId="formBasicText">
            <Row className="clearfix">
              <Col md={6}>
                <ControlLabel>{I18n.t('venues.manage_discounts.create_modal.start_date')}</ControlLabel>
                <DatePicker
                  selected={this.state.start_date}
                  minDate={moment()}
                  maxDate={this.state.end_date ? this.state.end_date : moment().add(50, "years")}
                  selectsStart={this.state.start_date && this.state.end_date}
                  startDate={this.state.start_date}
                  endDate={this.state.end_date}
                  onChange={this.handleDateChange.bind(this, 'start_date')}
                  dateFormat='DD/MM/YYYY'
                  className='form-control'
                  isClearable={true}
                  placeholderText={I18n.t('venues.manage_discounts.create_modal.start_date')}
                />
              </Col>
              <Col md={6}>
                <ControlLabel>{I18n.t('venues.manage_discounts.create_modal.end_date')}</ControlLabel>
                <DatePicker
                  selected={this.state.end_date}
                  minDate={this.state.start_date ? this.state.start_date : moment()}
                  selectsEnd={this.state.start_date && this.state.end_date}
                  startDate={this.state.start_date}
                  endDate={this.state.end_date}
                  onChange={this.handleDateChange.bind(this, 'end_date')}
                  dateFormat='DD/MM/YYYY'
                  className='form-control'
                  isClearable={true}
                  placeholderText={I18n.t('venues.manage_discounts.create_modal.end_date')}
                />
              </Col>
            </Row>
          </FormGroup>
          <FormGroup controlId="formBasicText">
            <Row className="clearfix">
              <Col md={6}>
                <ControlLabel>{I18n.t('venues.manage_discounts.create_modal.sports')}</ControlLabel>
                 <RemoteSelect
                   name="court_sports"
                   value={this.state.court_sports}
                   changeHandler={this.handleDropDownChange.bind(this, 'court_sports')}
                   placeholder={I18n.t('venues.manage_discounts.create_modal.sports')}
                   multi={true}
                   clearable={true}
                   url={`/api/venues/${this.props.venue_id}/sports.json`}
                 />
              </Col>
              <Col md={6}>
                <ControlLabel>{I18n.t('venues.manage_discounts.create_modal.court_type')}</ControlLabel>
                 <RemoteSelect
                   name="court_type"
                   value={this.state.court_type}
                   changeHandler={this.handleDropDownChange.bind(this, 'court_type')}
                   placeholder={I18n.t('venues.manage_discounts.create_modal.court_type')}
                   clearable={false}
                   multi={false}
                   url={`/api/courts/types.json`}
                 />
              </Col>
            </Row>
          </FormGroup>
          <FormGroup controlId="formBasicText">
            <Row className="clearfix">
              <Col md={12}>
                <ControlLabel>{I18n.t('venues.manage_discounts.create_modal.surfaces')}</ControlLabel>
                <RemoteSelect
                  name="court_surfaces"
                  value={this.state.court_surfaces}
                  clearable={true}
                  multi={true}
                  changeHandler={this.handleDropDownChange.bind(this, 'court_surfaces')}
                  placeholder={I18n.t('venues.manage_discounts.create_modal.surfaces')}
                  url={`/api/courts/surfaces.json`}
                />
              </Col>
            </Row>
          </FormGroup>
          <Row className="clearfix">
            <Col md={12}>
              <ControlLabel>{I18n.t('shared.time_limitations_selector.time_limitations')}</ControlLabel>
              <TimeLimitationsSelector
                time_limitations={this.state.time_limitations}
                update_time_limitations={this.handleTimeLimitationsChange.bind(this)}
              />
            </Col>
          </Row>
        </form>
      </Modal.Body>
    );
  }
}
