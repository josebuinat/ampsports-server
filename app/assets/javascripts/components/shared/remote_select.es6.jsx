// Helper component for sports dropdown 
class RemoteSelect extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
    }
  }

  componentDidMount() {
    axios.get(this.props.url)
         .then((response) => {
           this.setState({ options: response.data });
         });
  }

  render() {
    return(
     <Select
       name={this.props.name}
       options={this.state.options}
       isLoading={!this.state.options}
       value={this.props.value}
       onChange={this.props.changeHandler}
       multi={this.props.multi}
       clearable={this.props.clearable}
       placeholder={this.props.placeholder}
     />
    );
  }
}
