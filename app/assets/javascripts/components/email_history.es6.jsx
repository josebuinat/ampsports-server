var Row = ReactBootstrap.Row;
var Col = ReactBootstrap.Col;
var _emailHistory;
class EmailHistory extends React.Component {
  constructor(props) {
    super(props);
    _emailHistory = this;
    this.state = {
      mails: [],
      selected_mail: '',
      search_term: '',
      recipientListExpanded: false,
    };
    this.search_timer = null;
  }

  getCustomMails() {
    axios.get(`/api/venues/${this.props.venue_id}/custom_mails`, {
      params: { search_term: this.state.search_term }
    })
    .then((response) => {
      var mails = response.data.mails;
      this.setState({
        mails: mails,
        selected_mail: mails[0],
      })
    })
    .catch(error => {
      console.log(error);
      toastr.error("Error in fetching data");
    })
  }

  handleItemClick(mail) {
    this.setState({selected_mail: mail});
  }

  handleSearch(e) {
    this.setState({ search_term: e.target.value});
    let delay = 500;
    if (e.keyCode == 13) delay = 0;

    this.setState({ search: e.target.value}, this.run_search.bind(this, delay));
  }

  run_search(delay) {
    clearTimeout(this.search_timer);
    this.search_timer = setTimeout(this.getCustomMails.bind(this) , delay);
  }

  toggleRecipientContainer() {
    this.setState({recipientListExpanded: !this.state.recipientListExpanded})
  }

  render(){
    return (
      <div>
        <br />
        <Row className="clearfix">
          <Col md={4}>
            <ul className="item-group input-group">
              <i className="fa fa-search input-group-addon" />
              <FormControl
                type="text"
                name="search"
                value={this.state.search_term}
                placeholder={I18n.t('custom_mails.email_history.search_placeholder')}
                onChange={this.handleSearch.bind(this)}
                onKeyUp={this.handleSearch.bind(this)}
              />
          </ul>
          </Col>
        </Row>
        <br />
        <Row className="clearfix email-history-container">
          <Col md={4}>
            <ul className="scroll-height mail-list">
              {
                this.state.mails.map((mail, index) => {
                  return this.renderListItem(mail, index);
                })
              }
            </ul>
          </Col>
          <Col md={8} className="scroll-height">
            {this.renderSelectedMail()}
          </Col>
        </Row>
      </div>
    )
  }

  renderListItem(mail, index){
    const getClasses = () => {
      var selected = mail.id == this.state.selected_mail.id ? "selected" : "";
      return "list-group-item p-t-sm p-b-sm " + selected;
    }

    return(
      <li key={index} className={getClasses()}  onClick={this.handleItemClick.bind(this, mail)}>
        <Row className="clearfix">
          <Col lg={8}>
            <small className="text-muted"><em>{mail.from}</em></small>
          </Col>
          <Col lg={4}>
            <small className="text-muted pull-right">{ this.toMoment(mail.created_at).format("YYYY.MM.DD") }</small>
          </Col>
        </Row>
        <Row className="clearfix">
          <Col md={12}>
            <strong>{mail.subject}</strong>
          </Col>
        </Row>
      </li>
    )
  }

  renderSelectedMail() {
    const mail = this.state.selected_mail;
    if(!mail) return;
    return(
      <Row className="p-lg clearfix">
        <h1>{ mail.subject }</h1>
        <Row className="p-md">
          <Row>
            <Col md={2}><b>{I18n.t('custom_mails.email_history.from')}</b></Col>
            <Col md={10}>{ mail.from }</Col>
          </Row>
          <Row className="m-t-xs">
            <Col md={2}><b>{I18n.t('custom_mails.email_history.created_at')}</b></Col>
            <Col md={10}>{ this.toMoment(mail.created_at).format("YYYY.MM.DD") }</Col>
          </Row>
          <Row className="m-t-xs">
            <Col md={2}><b>{I18n.t('custom_mails.email_history.subject')}</b></Col>
            <Col md={10}>{ mail.subject }</Col>
          </Row>
          <Row className="clearfix m-t-xs">
            <Col md={2}><b>{I18n.t('custom_mails.email_history.to')}</b></Col>
            {this.renderRecipientsContainer(mail)}
          </Row>
          <hr />
        </Row>
        <Row>
          <Col><img className="img-responsive m-b-sm" src={mail.image_url}></img></Col>
        </Row>
        <Row>
          <Col>{ this.renderMailBody(mail.body) }</Col>
        </Row>

      </Row>
    )
  }

  renderMailBody(body_string) {
    const body_parts = body_string.split("\n");
    var html = body_parts.map((part, i) => {
      return <p key={i}>
        { part }
      </p>
    })
    return html;
  }

  renderRecipientsContainer(mail) {
    var containerClass = "recipientListContainer";
    if(this.state.recipientListExpanded){
      containerClass += " expanded";
    }

    var limit = () => {
      if(window.innerWidth >= 2400) return 270
      else if(window.innerWidth >= 1600) return 140
      else if(window.innerWidth >= 1200) return 100
      else if(window.innerWidth >= 800) return 85
      else if(window.innerWidth >= 500) return 80
      else return 50
    }

    return (
      <Col md={10}>
        <Row className="clearfix">
          <Col md={12}>
            <span>{I18n.t('custom_mails.email_history.recipients', {count: mail.to.length})}</span>
            { mail.to.join().length > limit() ?
              <span className="m-l-sm">
                (
                  <a  onClick={this.toggleRecipientContainer.bind(this)}>
                    {I18n.t('custom_mails.email_history.expand_collapse')}
                  </a>
                )
              </span> : ""
            }
          </Col>
        </Row>
        <Row className="clearfix">
          <Col md={12} className={containerClass}>
            {this.renderRecipients(mail)}
          </Col>
        </Row>
      </Col>
    )
  }

  renderRecipients(mail) {
    return mail.to.map((email, i) => {
      return (
        <b key={i} className="pull-left m-t-xs m-l-xs">{email}</b>
      )
    })
  }

  toMoment(strTime) {
    return moment(strTime, "YYYY-MM-DDTHH:mm:ss.SSSZ")
  }
}
