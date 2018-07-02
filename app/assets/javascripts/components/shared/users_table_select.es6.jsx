// Component rendering table of selectable users with pagination, sorting and search
// required props:
//   users_url - endpoint returning users JSON,
//               should support params: 'search', 'page', 'per_page', 'sort_by'
//   selectedUsersChanged() - callback, sends ids of selected users to callback
//
// Example:
// React.createElement(UsersTableSelect, {
//   'users_url': 'api/customers',
//   'selectedUsersChanged': function(ids) {
//     console.log(ids)
//   }
// }, null )

var Table = ReactBootstrap.Table;
var Row = ReactBootstrap.Row;
var Col = ReactBootstrap.Col;
var Button = ReactBootstrap.Button;
var Checkbox = ReactBootstrap.Checkbox;

class UsersTableSelect extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      users: [],
      selected_users: [],
      search: '',
      page: 1,
      per_page: 10,
      total_pages: 1,
      loading: false,
      sort_by: '',
      sort_order: '',
      sorted: false
    }
    this.searchTimer = null;
  }

  componentDidMount() {
    this.fetchUsers();
  }

  fetchUsers() {
    this.setState({ loading: true });
    return axios.get(this.props.users_url, {
      params: {
        search: this.state.search,
        page: this.state.page,
        per_page: this.state.per_page,
        sort_by: this.state.sort_by,
        sort_order: this.state.sort_order,
      }
    })
    .then((response)=> {
      this.setState({
        users: response.data.users,
        total_pages: response.data.total_pages,
        loading: false
      });
    })
    .catch((error)=> {
      console.log(error);
      error.response.data.errors.map((error)=> {
        toastr.error(error);
      });
    });
  }

  handleToggleSort(sort_by) {
    const SORT_ORDERS = ['', 'asc', 'desc'];
    var current_sort_order = this.state.sort_by ==  sort_by ? this.state.sort_order : '';
    var next_index = ((SORT_ORDERS.indexOf(current_sort_order) + 1) % SORT_ORDERS.length);
    var sort_order = SORT_ORDERS[next_index];
    this.setState({sort_by: sort_by, sort_order: sort_order}, this.sortTable)
  }

  sortTable() {
    this.fetchUsers()
      .then((response) =>{
        this.setState({sorted: true})
      })
  }

  findUser(id) {
    return this.state.users.find(x => x.id === id)
  }

  findSelectedUser(id) {
    return this.state.selected_users.find(x => x.id === id)
  }

  // starts search request after delay if typing ended
  // delay will be zero for [enter] press
  handleSearch(e) {
    let delay = 500;
    if (e.keyCode == 13) delay = 0;

    this.setState({ search: e.target.value, page: 1 }, this.runSearch.bind(this, delay));
  }

  runSearch(delay) {
    clearTimeout(this.searchTimer);
    this.searchTimer = setTimeout(this.fetchUsers.bind(this) , delay);
  }

  handlePageClick(page) {
    this.setState({ page: page }, this.fetchUsers.bind(this));
  }

  handleSelectUserChange(id, e) {
    if (e.target.checked) {
      let user = this.findUser(id);
      if (user) {
        let selected_users = this.state.selected_users;
        selected_users.push(user)
        this.setState({ selected_users: selected_users }, this.sendSelected.bind(this));
      }
    } else {
      if (this.findSelectedUser(id)) {
        this.setState({ selected_users: this.state.selected_users.filter(x => x.id != id) },
                        this.sendSelected.bind(this));
      }
    }
  }

  sendSelected() {
    this.props.selectedUsersChanged(this.state.selected_users.map((user)=>{ return user.id }))
  }

  render() {
    return(
      <div>
        <Row className="clearfix">
          <Col md={12}>
            <FormControl
              type="text"
              name="search"
              value={this.state.search}
              placeholder={I18n.t('shared.users_table_select.search_placeholder')}
              onChange={this.handleSearch.bind(this)}
              onKeyUp={this.handleSearch.bind(this)}
            />
          </Col>
        </Row>
        <Table responsive>
          <thead>
            <tr>
              <th>{I18n.t('shared.users_table_select.full_name')} {this.render_sort_button('full_name')}</th>
              <th>{I18n.t('shared.users_table_select.email')} {this.render_sort_button('email')}</th>
              <th>{I18n.t('shared.users_table_select.phone_number')} {this.render_sort_button('phone_number')}</th>
              <th>{I18n.t('shared.users_table_select.address')} {this.render_sort_button('address')}</th>
              <th></th>
            </tr>
          </thead>
          {this.render_body()}
        </Table>
        <div className="text-center">
          <Pagination
            page={this.state.page}
            total_pages={this.state.total_pages}
            onPageClick={this.handlePageClick.bind(this)}
          />
        </div>
      </div>
    )
  }

  render_body() {
    if (this.state.users.length) {
      return(this.render_users())
    }
    else {
      return(
        <tbody>
          <tr>
            <td colSpan="9">
              {I18n.t('shared.users_table_select.empty')}
            </td>
          </tr>
        </tbody>
      )
    }
  }

  render_users() {
    let users = this.state.users.map((user, index)=> {
      return(this.render_user(user, index));
    });

    return(
      <tbody>
        {users}
      </tbody>
    )
  }

  render_user(user, index) {
    return(
      <tr key={user.id}>
        <td>{user.first_name} {user.last_name}</td>
        <td>{user.email}</td>
        <td>{user.phone_number}</td>
        <td>{[user.city, user.street_address, user.zipcode].filter(n => n).join(', ')}</td>
        <td>
          <Checkbox
            onChange={this.handleSelectUserChange.bind(this, user.id)}
            value={user.id}
            checked={this.findSelectedUser(user.id) && 1}
            >
          </Checkbox>
        </td>
      </tr>
    )
  }

  render_sort_button(sort_by) {
    var sortClassName = 'fa fa-sort';
    if(this.state.sort_by == sort_by && this.state.sorted == true && this.state.sort_order) {
      sortClassName += `-${this.state.sort_order}`;
    }

    return(
      <span>
        <i
          className={`m-l-xs cursor-pointer ${sortClassName}`}
          onClick={this.handleToggleSort.bind(this, sort_by)}
        />
      </span>
    )
  }
}
