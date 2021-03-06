<?php

namespace Whathood\Controller;

use Zend\Mvc\Controller\AbstractActionController;
use Zend\View\Model\ViewModel;
use Whathood\Entity\WhathoodUser;

/**
 * Description of WhathoodController
 *
 * @author Jim Smiley twitter:@jimRsmiley
 */
class BaseController extends AbstractActionController {

    use ControllerMapperTrait;

    // a more accurate function description
    public function getRequestParameter($key) {
        $val = $this->getUriParameter($key);
        return str_replace('+',' ',$val);
    }

    /**
     *  return the route parameter replacing any pluses,
     *  useful for console route params which can't have white space values
     */
    public function paramFromRoute($key) {
        $val = $this->params()->fromRoute($key);
        return str_replace('+',' ',$val);
    }

    /**
     * in order of trying:
     *      query
     *      route
     */
    public function getUriParameter($key) {
        $on_console = $this->getRequest() instanceof \Zend\Console\Request;

        if( !$on_console and $this->params()->fromQuery($key) != null )
            return $this->params()->fromQuery($key);
        if( $this->getEvent()->getRouteMatch()->getParam($key) != null )
            return $this->getEvent()->getRouteMatch()->getParam($key);
        return false;
    }

    /**
     * our view scripts need breadcrumbs quite regularly so let's use this model
     * to create our view model with the selected params and add on region, user
     * and neighborhood names so we don't have to keep doing it.
     *
     * @param type $params
     */
    public function getViewModel( $params ) {

        $breadCrumbParams = array(
            'regionName'    => $this->getUriParameter('region_name'),
            'neighborhoodName' => $this->getUriParameter('neighborhood_name'),
        );

       $newParams = array_merge($breadCrumbParams,$params);
       return new ViewModel( $newParams );
    }

    public function getUser() {
	    if($this->zfcUserAuthentication()->hasIdentity()) {
		    return $this->zfcUserAuthentication()->getIdentity();
	    }
	    return null;
    }

	public function getUserRoleNames() {
		$user = $this->getUser();
		$role_names = array();
		if( $user) {
			foreach($user->getRoles() as $role) {
				array_push($role_names, $role->getRoleId());
			}
		}
		return $role_names;
	}

    public function getWhathoodUser() {
        return \Whathood\Entity\WhathoodUser::build($this->getRequest());
    }

    public function whathoodConfig() {
        return $this->getServiceLocator()->get('Whathood\Config');
    }

    protected function _getLogger() {
        return $this->getServiceLocator()->get('Whathood\Logger');
    }

    protected function _getConsoleLogger() {
        return $this->getServiceLocator()->get('Whathood\ConsoleLogger');
    }

    public function logger() {
        if ( $this->getRequest() instanceof \Zend\Console\Request) {
            return $this->_getConsoleLogger();
        }
        else {
            return $this->_getLogger();
        }
    }

    public function messageQueue() {
        return $this->queue('message_queue');
    }

    public function pushEmailJob(array $emailJobData) {
        $this->queue('message_queue')
            ->push('Whathood\Job\EmailJob',$emailJobData);
    }
}

?>
